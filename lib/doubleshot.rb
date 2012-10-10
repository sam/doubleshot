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
    if path.exist? and lockfile.exist? and path.mtime > lockfile.mtime
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
    if lockfile.exist? and classpath_cache.exist? and lockfile.mtime > classpath_cache.mtime
      classpath_cache.rm
    end
    # END: Cleanup tasks

    # BEGIN: JAR loading
    if classpath_cache.exist?
      # We survived the cleanup checks, go ahead and just load
      # the cached version of your JARs.
      YAML::load(classpath_cache).each_pair do |jar, path|
        lockfile.jars.fetch(jar).path = path
        require path
      end
    else
      # No classpath_cache exists, we must resolve the paths
      # to our dependencies, then store the results in
      # classpath_cache for future processes to use.

      # This is for bootstrapping Doubleshot itself only!
      if @config.project == "doubleshot"
        # Caching the generated classpath is an optimization
        # for continuous testing performance, so we're not
        # shelling out to 'mvn' on every test run.
        classpath_rb = Pathname(".classpath.rb")
        if !classpath_rb.exist? || Pathname("pom.xml").mtime > classpath_rb.mtime
          classpath_rb.open("w+") do |file|
            file.puts "classpath = Doubleshot::current.classpath"
            out = `mvn dependency:build-classpath`.split($/)
            out[out.index(out.grep(/Dependencies classpath\:/).first) + 1].split(":").each do |jar|
              file.puts "classpath << #{jar.to_s.inspect}"
            end
            file.puts "classpath.each { |jar| require jar }"
          end
        end

        require classpath_rb
      else
        require "doubleshot/resolver"

        if @config.mvn_repositories.empty?
          @config.mvn_repository Resolver::JarResolver::DEFAULT_REPOSITORY
        end

        resolver = Resolver::JarResolver.new(*@config.mvn_repositories)
        jars = nil

        if lockfile.exist?
          jars = JarDependencyList.new
          lockfile.jars.each do |jar|
            jars.add jar
          end
        else
          jars = @config.runtime.jars + @config.development.jars
        end

        resolver.resolve! jars

        jars.each { |jar| lockfile.add jar }
        # lockfile.flush!

        cache = {}
        jars.each do |jar|
          cache[jar.to_s] = jar.path
          require jar.path
        end

        classpath_cache.open("w+") do |file|
          file << cache.to_yaml
        end
      end
    end
    # END: JAR loading
  end

  def classpath_cache
    @classpath_cache ||= Pathname(".classpath.cache")
  end
end
