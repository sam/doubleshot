class Doubleshot::CLI::Commands::Test < Doubleshot::CLI
  def self.summary
    <<-EOS.margin
      A test harness that watches files, builds your
      source, and executes tests based on filename
      conventions. The location of your tests is
      determined by the 'config.source.tests'
      attribute of your Doubleshot configuration.
    EOS
  end

  def self.options
    Options.new do |options|
      options.banner = "Usage: doubleshot test [options]"

      options.separator ""
      options.separator "Options:"

      options.build = false
      options.on "--build", "Performs a Build before running the tests" do
        options.build = true
      end

      options.ci_test = false
      options.on "--ci", "Run all tests, then exit. (No continuous listening for file changes.)" do
        options.ci_test = true
        options.build = true
      end

      options.separator ""
      options.separator "Summary: #{summary}"
    end
  end

  def self.start(args)
    options = self.options.parse!(args)
    doubleshot = Doubleshot::current

    if options.ci_test
      if doubleshot.lockfile.exist?
        puts "--ci: Removing lockfile"
        doubleshot.lockfile.delete
      end

      if doubleshot.classpath_cache.exist?
        puts "--ci: Removing .classpath.cache"
        doubleshot.classpath_cache.delete
      end

      if doubleshot.config.target.exist?
        puts "--ci: Removing target build directory"
        doubleshot.config.target.rmtree
      end
    end

    if options.build
      Doubleshot::CLI::Commands::Build.start(options.build ? [] : [ "--conditional" ])
    else
      require "doubleshot/setup"
    end

    require "listen"

    watcher = new(doubleshot.config, options.ci_test)
    watcher.run
  end

  def initialize(config, ci_test)
    @config = config
    @interrupted = false
    @ci_test = ci_test

    # Hit Ctrl-C once to re-run all specs; twice to exit the program.
    Signal.trap("INT") do
      if @interrupted
        puts "\nShutting down..."
        exit 0
      else
        @interrupted = true
        run_all_specs
        @interrupted = false
      end
    end
  end

  def run
    if @ci_test
      run_all_specs
    else
      # Output here just so you know when changes will be
      # picked up after you start the program.
      puts "Listening for changes..."
      listener.start
    end
  end

  private
  def listener
    # This creates a MultiListener
    Listen.to(@config.source.tests.to_s, @config.source.ruby.to_s).change do |modified, added, removed|
      modified.each do |location|
        path = Pathname(location)
        next unless path.extname == ".rb"

        test = if path.basename.to_s =~ /_(spec|test).rb/ && path.child_of?(@config.source.tests)
          path
        else
          relative_path = path.relative_path_from(@config.source.ruby.expand_path)
          matcher = relative_path.sub(/(\w+)\.rb/, "\\1_{spec,test}.rb")
          matchers = [ matcher, Pathname(matcher.to_s.split("/")[1..-1].join("/")) ]

          match = matchers.detect do |matcher|
            if match = Pathname::glob(@config.source.tests + matcher).first
              break match
            end
          end
        end

        if test && test.exist?
          duration = Time::measure do
            puts "\n --- Running test for #{test.to_s} ---\n\n"

            org.jruby.Ruby.newInstance.executeScript <<-RUBY, test.to_s
              begin
                require #{test.to_s.inspect}
                MiniTest::Unit.new._run
              rescue java.lang.Throwable, Exception => e
                puts e.to_s, e.backtrace.join("\n")
              end
            RUBY
          end

          puts "Completed in #{duration}s"
        else
          puts "\nNo matching test for #{path.relative_path_from(@config.source.ruby.expand_path).to_s}"
        end
      end
    end
  end

  def run_all_specs
    exit_status = false
    duration = Time::measure do

      puts "\n --- Running all tests ---\n\n"

      script = <<-RUBY
        begin
          #{
            Pathname::glob(@config.source.tests + "**/*_{spec,test}.rb").map do |path|
              "require #{path.to_s.inspect}"
            end.join("\n")
          }
          MiniTest::Unit.new._run
        rescue java.lang.Throwable, Exception => e
          puts e.to_s, e.backtrace.join("\n")
        end
      RUBY
      # puts "SCRIPT:", script
      exit_status = org.jruby.Ruby.newInstance.executeScript script, "all-specs"
    end

    puts "Completed in #{duration}s"
    return exit_status
  end

end # class Doubleshot::CLI::Commands::Test < Doubleshot::CLI
