class Doubleshot::CLI::Commands::Install < Doubleshot::CLI

  def self.summary
    <<-EOS.margin
      Install your project as a Rubygem.
    EOS
  end

  def self.options
    Options.new do |options|
      options.banner = "Usage: doubleshot install"
      options.separator ""
      options.separator "Options"

      options.test = true
      options.on "--no-test", "Disable testing as a packaging prerequisite." do
        options.test = false
      end

      options.separator ""
      options.separator "Summary: #{summary}"
    end
  end

  def self.start(args)
    Doubleshot::CLI::Commands::Gem.start(args)

    require "rubygems/dependency_installer"

    installer = ::Gem::DependencyInstaller.new
    installer.install Doubleshot::current.config.gemspec.file_name

    return 0
  end
end
