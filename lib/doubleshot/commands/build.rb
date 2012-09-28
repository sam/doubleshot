class Doubleshot::CLI::Commands::Build < Doubleshot::CLI
  def self.summary
    <<-EOS.margin
      TODO
    EOS
  end

  def self.options
    OptionParser.new do |options|
      options.banner = "Usage: doubleshot build"
    end
  end
end