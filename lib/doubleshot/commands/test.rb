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

    @@pid_file = Pathname(".doubleshot_test.pid")
    if @@pid_file.exist? && !options.force_tests

      begin
        if Process.getpgid(@@pid_file.read.to_i)
          puts ".doubleshot_test.pid exists: Are you running tests elsewhere? (Use --force to override.)"
          exit 1
        end
      rescue Errno::ESRCH
        @@pid_file.delete
      end
    end

    @@pid_file.open("w") do |pid|
      pid << $$
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
          @@pid_file.delete if @@pid_file.exist?
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
      if @config.project == "doubleshot"
        Doubleshot::current.bootstrap!
        Doubleshot::current.build! false
      end
      exit_status = run_all_specs
      unless @force_tests
        @@pid_file.delete if @@pid_file.exist?
      end
      exit_status
    else
      # Output here just so you know when changes will be
      # picked up after you start the program.
      puts "Listening for changes..."
      listener.start
    end
  end

  private
  def listener
    require "listen"

    monitored = [
      @config.source.tests,
      @config.source.ruby,
      @config.source.java
    ].select(&:exist?).map(&:to_s)

    # This creates a MultiListener
    Listen.to(*monitored).change do |modified, added, removed|
      modified.each do |location|
        path = Pathname(location)

        next unless path.extname == ".rb" or path.extname == ".java"

        test = nil

        if path.child_of?(@config.source.tests)
          if path.basename.to_s =~ /_(spec|test).rb/
            test = path
          else
            next
          end
        else
          case path.extname
          when ".rb" then
            if @config.source.ruby.exist?
              test = path.relative_path_from(@config.source.ruby.expand_path)
            else
              next
            end
          when ".java" then
            if @config.source.java.exist?
              test = path.relative_path_from(@config.source.java.expand_path)
            else
              next
            end
          end

          matcher = test.sub(/(\w+)\.(rb|java)/, "\\1_{spec,test}.rb")
          matchers = [ matcher ]

          # If this is a nested path, then create a lower priority matcher
          # without the first portion of the path, so that a path like:
          #
          #   "lib/doubleshot/configuration/source_locations.rb"
          #
          # would search for the following paths:
          #
          #   test/doubleshot/configuration/source_locations_{spec,test}.rb
          #   test/configuration/source_locations_{spec,test}.rb
          #
          # So if you follow the exact lib structure convention in your test folder,
          # those files will get precedence, but otherwise, you can drop the
          # project-name so you don't have to nest ALL-THE-THINGS.
          unless matcher.basename == matcher
            matchers << Pathname(matcher.to_s.split("/")[1..-1].join("/"))
          end

          test = matchers.detect do |matcher|
            if match = Pathname::glob(@config.source.tests + matcher).first
              break match
            end
          end
        end

        if test && test.exist?
          if path.extname == ".java"
            Doubleshot::current.setup!
            Doubleshot::current.build! false
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
