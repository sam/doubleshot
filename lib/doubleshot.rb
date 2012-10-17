require "java"
require "pathname"
require "set"
require "yaml"

$:.unshift(Pathname(__FILE__).dirname)

unless Pathname($0).basename == "doubleshot" &&
  ARGV.first &&
  [ "install", "jar", "gem", "test" ].include?(ARGV.first)

  $:.unshift(Pathname(__FILE__).dirname.parent + "target")

  begin
    require "doubleshot.jar"
  rescue LoadError
    warn <<-EOS
WARN: doubleshot.jar not loaded
This probably means you're bootstrapping
a test. If you get this message from the
doubleshot gem, then the distribution is
broken.
EOS
  end
end

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
  attr_reader   :classpath

  def initialize
    @classpath = Set.new
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
      lockfile.delete
      classpath_cache.delete if classpath_cache.exist?
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
      classpath_cache.delete
    end
    # END: Cleanup tasks

    load_jars! unless @config.runtime.jars.empty? && @config.development.jars.empty?
  end

  def load_jars!
    if classpath_cache.exist?
      # We survived the cleanup checks, go ahead and just load
      # the cached version of your JARs.
      cached_paths = YAML::load(classpath_cache)

      lockfile.jars.each do |jar|
        jar.path = cached_paths[jar.to_s]
        begin
          require jar.path
          self.classpath << jar.path
        rescue LoadError
          warn "Could not load: #{jar.path.inspect}"
          raise
        end
      end
    else
      # No classpath_cache exists, we must resolve the paths
      # to our dependencies, then store the results in
      # classpath_cache for future processes to use.
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
        begin
          require jar.path
          self.classpath << jar.path
        rescue LoadError
          warn "Could not load: #{jar.path.inspect}"
          raise
        end
      end

      classpath_cache.open("w+") do |file|
        file << cache.to_yaml
      end
    end
  end

  def classpath_cache
    @classpath_cache ||= Pathname(".classpath.cache")
  end

  def bootstrap!
    if !@config.target.exist? || !lockfile.exist? || !classpath_cache.exist? || Pathname("pom.xml").mtime > classpath_cache.mtime
      # Dependencies classpath:
      paths = `mvn dependency:build-classpath`.split(/\bDependencies classpath\b/).last.split($/).grep(/\.jar\b/).map { |line| line.split(":") }.flatten
      coordinates = `mvn dependency:list`.split(/\bfiles have been resolved\b/).last.split($/).grep(/\bcompile$/).map do |line|
        line.split.last.sub /\:compile$/, ""
      end

      resolved = Hash[*coordinates.zip(paths).flatten]

      resolved.each_pair do |coordinate, path|
        require path
        self.classpath << path
        jar = Dependencies::JarDependency.new(coordinate)
        jar.path = path
        lockfile.add jar
      end

      lockfile.flush!

      classpath_cache.open("w+") do |file|
        file << resolved.to_yaml
      end
    else
      setup!
    end
  end
end
