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

      options.ci_test = false
      options.on "--ci", "Run all tests, then exit. (No continuous listening for file changes.)" do
        options.ci_test = true
        options.build = true
      end

      options.force_tests = false
      options.on "--force", "Run tests, even if doubleshot_test.pid exists." do
        options.force_tests = true
      end

      options.separator ""
      options.separator "Summary: #{summary}"
    end
  end

  def self.start(args)
    options = self.options.parse!(args)

    @@pid_file = Pathname::pwd + ".doubleshot_test.pid"
    if !@@pid_file.nil? && @@pid_file.exist? && !options.force_tests
      puts ".doubleshot_test.pid exists: Are you running tests elsewhere? (Use --force to override.)"
      exit 1
    end

    unless options.force_tests
      @@pid_file.open("w") do |file|
        file << $$
      end
    end

    doubleshot = Doubleshot::current

    if Pathname::glob(doubleshot.config.source.tests + "**/*_{spec,test}.rb").empty?
      puts "No tests found"
      return 0
    end

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

    require "listen"

    watcher = new(doubleshot.config, options.ci_test, options.force_tests)
    watcher.run
  end

  def initialize(config, ci_test, force_tests)
    @config = config
    @interrupted = false
    @ci_test = ci_test
    @force_tests = force_tests

    # Hit Ctrl-C once to re-run all specs; twice to exit the program.
    Signal.trap("INT") do
      if @interrupted
        puts "\nShutting down..."

        unless @force_tests
          @@pid_file.delete if !@@pid_file.nil? && @@pid_file.exist?
        end

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
      exit_status = run_all_specs
      unless @force_tests
        @@pid_file.delete if !@@pid_file.nil? && @@pid_file.exist?
      end
      exit_status
    else
      Doubleshot::CLI::Commands::Build.start([ "--conditional" ])
      # Output here just so you know when changes will be
      # picked up after you start the program.
      puts "Listening for changes..."
      listener.start
    end
  end

  private
  def listener
    # This creates a MultiListener
    Listen.to(@config.source.tests.to_s, @config.source.ruby.to_s, @config.source.java.to_s).change do |modified, added, removed|
      modified.each do |location|
        path = Pathname(location)

        next unless path.extname == ".rb" or path.extname == ".java"

        test = if path.basename.to_s =~ /_(spec|test).rb/ && path.child_of?(@config.source.tests)
          path
        else
          relative_path = if path.extname == ".rb"
                            path.relative_path_from(@config.source.ruby.expand_path)
                          else
                            path.relative_path_from(@config.source.java.expand_path)
                          end
          matcher = relative_path.sub(/(\w+)\.(rb|java)/, "\\1_{spec,test}.rb")
          matchers = [ matcher, Pathname(matcher.to_s.split("/")[1..-1].join("/")) ]

          match = matchers.detect do |matcher|
            if match = Pathname::glob(@config.source.tests + matcher).first
              break match
            end
          end
        end

        if test && test.exist?
          if path.extname == ".java"
            Doubleshot::CLI::Commands::Build.start([])
          end

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

      Doubleshot::CLI::Commands::Build.start([ "--conditional" ])

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
