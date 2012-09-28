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
end