class Doubleshot::CLI::Init < Doubleshot::CLI
  def self.summary
    <<-EOS.margin
      Generate a Doubleshot file for your project.
      This command is interactive.
    EOS
  end
end