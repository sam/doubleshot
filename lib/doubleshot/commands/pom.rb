class Doubleshot::CLI::Commands::Pom < Doubleshot::CLI

  def self.summary
    <<-EOS.margin
      Generate a pom.xml based on your Doubleshot file.
    EOS
  end

  def self.options
    Options.new do |options|
      options.banner = "Usage: doubleshot pom"

      options.separator ""
      options.separator "Summary: #{summary}"
    end
  end

  def self.start(args)
    require "doubleshot/pom"

    pom = Pathname("pom.xml")
    pom.rename("pom.xml.#{Time.now.to_i}") if pom.exist?
    pom.open("w+") do |file|
      file << Doubleshot::Pom.new(Doubleshot::current.config).to_s
    end

    return 0
  end
end
