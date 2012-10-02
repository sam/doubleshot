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
      options.separator "Summary: #{summary}"
    end
  end

  def self.start(args)
    config = Doubleshot::current.config

    compiler = Doubleshot::Compiler.new(config.source.java, config.target)
    # compiler.classpath = config.classpath
    compiler.build!

    # TODO:
    # download JAR dependencies
    # setup correct class-path
    # download Gem dependencies
    # exit

    return true
  end
end