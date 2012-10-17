class Doubleshot::CLI::Commands::Jar < Doubleshot::CLI

  def self.summary
    <<-EOS.margin
      Package your project as a JAR.
    EOS
  end

  def self.options
    Options.new do |options|
      options.banner = "Usage: doubleshot jar"
      options.separator ""
      options.separator "Options"

      options.test = true
      options.on "--no-test", "Disable testing as a packaging prerequisite." do
        options.test = false
      end

      options.sparse = false
      options.on "--sparse", "Don't include JAR dependencies in your JAR. (For example, if you want to use Maven.)" do
        options.sparse = true
      end

      options.separator ""
      options.separator "Summary: #{summary}"
    end
  end

  def self.start(args)
    options = self.options.parse!(args)
    doubleshot = Doubleshot::current

    if options.test
      puts "Executing tests..."
      if Doubleshot::CLI::Commands::Test.start([ "--ci" ]) != 0
        STDERR.puts "Test failed, aborting JAR creation."
        return 1
      end
    else
      Doubleshot::CLI::Commands::Build.start(args)
    end

    unless Pathname::glob(doubleshot.config.source.java + "**/*.java").empty?
      target = doubleshot.config.target

      jarfile = (target + "#{doubleshot.config.project}.jar")
      jarfile.delete if jarfile.exist?

      ant.jar jarfile: jarfile, basedir: target do
        manifest{
          attribute(:name => "Main-Class", :value => doubleshot.config.java_main)
        }
        fileset dir: doubleshot.config.source.ruby.parent, includes: doubleshot.config.source.ruby.to_s + "/**/*"
        unless options.sparse
          doubleshot.lockfile.jars.each do |jar|
            zipfileset src: jar.path.expand_path, excludes: "META-INF/*.SF"
          end
        end
      end
    end

    return 0
  end
end
