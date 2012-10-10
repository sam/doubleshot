class Doubleshot::CLI::Commands::Gem < Doubleshot::CLI

  def self.summary
    <<-EOS.margin
      Package your project as a Rubygem, bundling any
      JAR dependencies and Java classes in with the distribution.
    EOS
  end

  def self.options
    Options.new do |options|
      options.banner = "Usage: doubleshot gem"
      options.separator ""
      options.separator "Options"

      options.test = true
      options.on "--no-test", "Disable testing as a build prerequisite." do
        options.test = false
      end

      options.separator ""
      options.separator "Summary: #{summary}"
    end
  end

  def self.start(args)
    options = self.options.parse!(args)

    # TODO:
    # compile Java
    # download Jars and add them to the gemspec require_paths (I THINK).
    config = Doubleshot::current.config

    # TODO: This is version specific since in HEAD they've changed this to Gem::Package::build.
    ::Gem::Builder.new(config.gemspec).build

    return 0
  end
end