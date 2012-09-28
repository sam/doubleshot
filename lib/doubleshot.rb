require "pathname"
require "set"

$:.unshift(Pathname(__FILE__).dirname)

require "ruby/gem/requirement"
require "ruby/string"
require "ruby/blank"
require "ruby/pathname"
require "doubleshot/readonly_collection"
require "doubleshot/configuration"

class Doubleshot
  def initialize(&b)
    @config = Doubleshot::Configuration.new
    yield @config
  end

  def build_gemspec
    @config.gemspec.to_ruby
  end

  def config
    @config
  end
end
