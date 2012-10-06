require_relative "../doubleshot"

config = Doubleshot::current.config

# This will add your compiled sources to $CLASSPATH so
# you can reference your Java classes in Ruby.
if config.target.exist?
  $CLASSPATH << config.target.to_url
end

# TODO:
#   config.jars.each { |jar| require jar.path }

# This is for bootstrapping Doubleshot itself only!
if config.gemspec.name == "doubleshot"
  # Caching the generated classpath is an optimization
  # for continuous testing performance, so we're not
  # shelling out to 'mvn' on every test run.
  classpath = Pathname(".classpath.rb")
  if !classpath.exist? || Pathname("pom.xml").mtime > classpath.mtime
    classpath.open("w+") do |file|
      out = `mvn dependency:build-classpath`.split($/)
      out[out.index(out.grep(/Dependencies classpath\:/).first) + 1].split(":").each do |jar|
        file.puts "require #{jar.to_s.inspect}"
      end
    end
  end

  require classpath
end

# gemfile = Pathname "Gemfile"
# gemfile_lock = Pathname "Gemfile.lock"

require "doubleshot/resolver"

# install_gems = -> do
#   require "bundler"
#   require "bundler/cli"
#   Bundler::CLI.new.install
# end

# if gemfile.exist?
#   begin
#     install_gems.call if !gemfile_lock.exist? || gemfile.mtime > gemfile_lock.mtime
#     require "bundler/setup"
#   end
# end

# install_jars = -> do
#   require "jbundler/cli"
#   JBundler::Cli.new.install
# end

# jarfile = Pathname "Jarfile"
# jarfile_lock = Pathname "Jarfile.lock"

# if jarfile.exist?
#   require "bundler" unless Object::const_defined?("Bundler")
#   require "jbundler"
#   install_jars.call if !jarfile_lock.exist? || jarfile.mtime > jarfile_lock.mtime
# end

# require "ant"

# source = Pathname "ext/java"
# target = Pathname "target"

# target.mkdir unless target.exist?

# ant.path id: "classpath" do  
#   fileset dir: target.to_s
#   JBUNDLER_CLASSPATH.each do |jar|
#     fileset dir: Pathname(jar).dirname
#   end
# end

# ant.javac srcdir: source.to_s, destdir: target.to_s, debug: "yes", includeantruntime: "no", classpathref: "classpath"

# $CLASSPATH << target.to_s