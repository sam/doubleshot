require "pathname"

$:.unshift(Pathname(__FILE__).dirname)

require "doubleshot/configuration"

class Doubleshot
  def initialize(&b)
    @config = Doubleshot::Configuration.new
    yield @config
  end

  def build_gemspec
    @config.gemspec.to_ruby
  end
end
