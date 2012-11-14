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

    if doubleshot.config.project == "doubleshot"
      puts "Bootstrapping Doubleshot build with Maven..."
      doubleshot.bootstrap!
    else
      puts "Performing Doubleshot setup to resolve dependencies..."
      doubleshot.setup!
    end

    doubleshot.build! options.conditional
    return 0
  end
end
