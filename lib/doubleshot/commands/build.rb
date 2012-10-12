class Doubleshot::CLI::Commands::Build < Doubleshot::CLI
  def self.summary
    <<-EOS.margin
      Download all dependencies and compile sources so that you
      can use the project directly without installation, such
      as with IRB.

      NOTE: Packaging and testing have a dependency on this
      command. You don't need to build as a prerequisite.
    EOS
  end

  def self.options
    Options.new do |options|
      options.banner = "Usage: doubleshot build"
      options.separator ""
      options.separator "Options"

      options.classpath = []
      options.on "--classpath CLASSPATH", "Manually set the CLASSPATH the compiler should use." do |classpath|
        options.classpath = classpath.to_s.split(":")
      end

      options.conditional = false
      options.on "--conditional", "Perform a conditional build (determine if there are pending files)." do
        options.conditional = true
      end

      options.separator ""
      options.separator "Summary: #{summary}"
    end
  end

  def self.start(args)
    options = self.options.parse!(args)
    doubleshot = Doubleshot::current

    if options.conditional && doubleshot.config.target.exist?
      doubleshot.config.target.rmtree
    end

    compiler = Doubleshot::Compiler.new(doubleshot.config.source.java, doubleshot.config.target)

    if doubleshot.config.project == "doubleshot"
      puts "Bootstrapping Doubleshot build with Maven..."
      doubleshot.bootstrap!
    else
      puts "Performing Doubleshot setup to resolve dependencies..."
      doubleshot.setup!
    end

    if options.classpath.empty?
      doubleshot.classpath
    else
      options.classpath
    end.each do |path|
      compiler.classpath << path
    end

    puts "[INFO] Using #{compiler.classpath}"
    puts

    if compiler.pending? || !options.conditional
      puts "Compiling..."
      compiler.build!
    else
      puts "Conditional build: No source changes."
    end

    return 0
  end
end
