require "pathname"

gemfile = Pathname "Gemfile"
gemfile_lock = Pathname "Gemfile.lock"

install_gems = -> do
  require "bundler"
  require "bundler/cli"
  Bundler::CLI.new.install
end

if gemfile.exist?
  begin
    install_gems.call if !gemfile_lock.exist? || gemfile.mtime > gemfile_lock.mtime
    require "bundler/setup"
  end
end

install_jars = -> do
  require "jbundler/cli"
  JBundler::Cli.new.install
end

jarfile = Pathname "Jarfile"
jarfile_lock = Pathname "Jarfile.lock"

if jarfile.exist?
  require "bundler" unless Object::const_defined?("Bundler")
  require "jbundler"
  install_jars.call if !jarfile_lock.exist? || jarfile.mtime > jarfile_lock.mtime
end

require "ant"

source = Pathname "ext/java"
target = Pathname "target"

target.mkdir unless target.exist?

ant.path id: "classpath" do
  fileset dir: target.to_s
  JBUNDLER_CLASSPATH.each do |jar|
    fileset dir: Pathname(jar).dirname
  end
end

ant.javac srcdir: source.to_s, destdir: target.to_s, debug: "yes", includeantruntime: "no", classpathref: "classpath"

$CLASSPATH << target.to_s

ant.jar jarfile: "example.jar", basedir: target.to_s
