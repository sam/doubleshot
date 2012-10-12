require "java"
require "pathname"
require "set"
require "yaml"

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

  attr_accessor :path
  attr_reader   :config
  attr_reader   :lockfile

  def initialize
    @config = Doubleshot::Configuration.new
    @lockfile = Doubleshot::Lockfile.new
    yield @config if block_given?
  end

  def build_gemspec
    @config.gemspec.to_ruby
  end

  def self.current
    @current ||= load
  end

  def self.load(path = "Doubleshot")
    path = Pathname(path)
    doubleshot = eval(path.read)
    doubleshot.path = path
    doubleshot
  end

  # This modifies the current environment.
  # Do not run this unless you really know what you're
  # doing (modifying global shared state). The recommended
  # way to call this, and ensure it's only called once for
  # your current configuration, is to:
  #   require "doubleshot/setup"
  def setup!
    # This will add your compiled sources to $CLASSPATH so
    # you can reference your Java classes in Ruby.
    $CLASSPATH << @config.target.to_url if @config.target.exist?

    # BEGIN: Cleanup tasks
    #
    # Delete +lockfile+ and +classpath_file+ if the
    # Doubleshot file has been modified since they were written.
    #
    # SCENARIO: You will run into this if you've added a new dependency
    # (or made any other change) to your Doubleshot configuration file.
    if path.exist? && lockfile.exist? && path.mtime > lockfile.mtime
      lockfile.rm
      classpath_cache.rm if classpath_cache.exist?
    end

    # If the above is not true, your Doubleshot file hasn't
    # been modified, but you may have updated the +lockfile+,
    # in which case we need to check if the classpath_cache is
    # still current, or needs to be flushed.
    #
    # SCENARIO: You will typically run into this if you've cloned
    # a Doubleshotted project, where the Doubleshot file and Lockfile
    # have been committed to the repository, but you have not ever
    # started the project on your local machine.
    if lockfile.exist? && classpath_cache.exist? && lockfile.mtime > classpath_cache.mtime
      classpath_cache.rm
    end
    # END: Cleanup tasks

    # BEGIN: JAR loading
    if classpath_cache.exist?
      # We survived the cleanup checks, go ahead and just load
      # the cached version of your JARs.
      cached_paths = YAML::load(classpath_cache)
      lockfile.jars.each do |jar|
        jar.path = cached_paths[jar.to_s]
        # TODO: This should never happen, but because of unknown munging
        # by Aether.resolve!, Aether#classpath_map may return keys that
        # don't match up to jar.to_s.
        require jar.path unless jar.path.blank?
      end
    else
      # No classpath_cache exists, we must resolve the paths
      # to our dependencies, then store the results in
      # classpath_cache for future processes to use.

      # This is for bootstrapping Doubleshot itself only!
      bootstrap! if @config.project == "doubleshot"

      require "doubleshot/resolver"

      if @config.mvn_repositories.empty?
        @config.mvn_repository Resolver::JarResolver::DEFAULT_REPOSITORY
      end

      resolver = Resolver::JarResolver.new(*@config.mvn_repositories)
      jars = nil

      if lockfile.exist?
        jars = Dependencies::JarDependencyList.new
        lockfile.jars.each do |jar|
          jars.add jar
        end
      else
        jars = @config.runtime.jars + @config.development.jars
      end

      resolver.resolve! jars

      jars.each { |jar| lockfile.add jar }
      lockfile.flush!

      cache = {}
      jars.each do |jar|
        cache[jar.to_s] = jar.path
        # TODO: This should never happen, but because of unknown munging
        # by Aether.resolve!, Aether#classpath_map may return keys that
        # don't match up to jar.to_s.
        require jar.path unless jar.path.blank?
      end

      classpath_cache.open("w+") do |file|
        file << cache.to_yaml
      end
    end
    # END: JAR loading
  end

  def classpath_cache
    @classpath_cache ||= Pathname(".classpath.cache")
  end

  private
  def bootstrap!
    if !classpath_cache.exist? || Pathname("pom.xml").mtime > classpath_cache.mtime
      classpath_cache.open("w+") do |file|
        paths = `mvn dependency:build-classpath`.split($/).grep(/\.jar\b/).map { |line| line.split(":") }.flatten
        artifacts = `mvn dependency:list`.split($/).grep(/\bcompile$/).map { |line| line.split.last.sub /\:compile$/, "" }
        # Get artifacts in same order here...
        # Match up paths and buildr-style strings into a hash.
        file << Hash[*artifacts.zip(paths).flatten].to_yaml
        paths.each { |path| require path }
      end
    end
  end
end
