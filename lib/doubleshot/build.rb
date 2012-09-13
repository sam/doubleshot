require "pathname"

if (Pathname::pwd + "Gemfile").exist?
  begin
    require "bundler/setup"
  rescue LoadError
    require "bundler/cli"
    Bundler::CLI.new.install
    retry
  end
end

if (Pathname::pwd + "Jarfile").exist?
  require "bundler"
  require "jbundler/cli"
  JBundler::Cli.new.install
end

require "ant"
require "pathname"

source = (Pathname::pwd + "lib" + "java")
target = (Pathname::pwd + "target")

target.mkdir unless target.exist?
ant.javac srcdir: source.to_s, destdir: target.to_s, debug: "yes", includeantruntime: "no"

require "java"
$CLASSPATH << target.to_s