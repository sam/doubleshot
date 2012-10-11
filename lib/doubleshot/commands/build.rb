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

      options.separator ""
      options.separator "Summary: #{summary}"
    end
  end

  def self.start(args)
    options = self.options.parse!(args)
    doubleshot = Doubleshot::current
    doubleshot.setup!

    compiler = Doubleshot::Compiler.new(doubleshot.config.source.java, doubleshot.config.target)

    if options.classpath.empty?
      doubleshot.lockfile.jars.map(&:path)
    else
      options.classpath
    end.each do |path|
      compiler.classpath << path
    end

    compiler.build!

    # TODO:
    # download JAR dependencies
    # download Gem dependencies
    # exit

    return 0
  end
end
