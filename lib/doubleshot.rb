require "pathname"
require "set"

$:.unshift(Pathname(__FILE__).dirname)

require "doubleshot/configuration"
require "doubleshot/readonly_collection"
require "ruby/gem/requirement"

class Doubleshot
  def initialize(&b)
    @config = Doubleshot::Configuration.new
    yield @config
  end

  def build_gemspec
    @config.gemspec.to_ruby
  end
end
