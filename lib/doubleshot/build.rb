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

source = (Pathname::pwd + "lib" + "java")
target = (Pathname::pwd + "target")

target.mkdir unless target.exist?

ant.path id: "classpath" do  
  fileset dir: target.to_s
  JBUNDLER_CLASSPATH.each do |jar|
    fileset dir: Pathname(jar).dirname
  end
end

ant.javac srcdir: source.to_s, destdir: target.to_s, debug: "yes", includeantruntime: "no", classpathref: "classpath"

require "java"
$CLASSPATH << target.to_s