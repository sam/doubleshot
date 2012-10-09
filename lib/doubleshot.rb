require "pathname"
require "set"

$:.unshift(Pathname(__FILE__).dirname)

require "ruby/gem/requirement"
require "ruby/string"
require "ruby/blank"
require "ruby/pathname"
require "ruby/kernel"
require "ruby/time"
require "doubleshot/readonly_collection"
require "doubleshot/configuration"
require "doubleshot/compiler"
require "doubleshot/lockfile"

class Doubleshot
  def initialize(&b)
    @config = Doubleshot::Configuration.new
    @lockfile = Doubleshot::Lockfile.new
    yield @config
  end

  def build_gemspec
    @config.gemspec.to_ruby
  end

  def config
    @config
  end

  def lockfile
    @lockfile
  end

  def self.current
    @current ||= load
  end

  def self.load
    eval(Pathname("Doubleshot").read)
  end
end
