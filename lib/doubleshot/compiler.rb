require "java"
require "ant"
require "doubleshot/compiler/classpath"

class Doubleshot
  class Compiler

    def initialize(source, target)
      @source = Pathname(source.to_s)
      @target = Pathname(target.to_s)
      @classpath = Classpath.new
    end

    attr_reader :source, :target, :classpath

    def build!(add_target_to_current_classpath = false)
      @target.mkdir unless @target.exist?
      
      # The JRuby ant integration throws JRuby Persistence
      # warnings that you can't supress, so we run it
      # inside of a Kernel#silence block.
      silence do
        # Since the ant.path block is instance_evaled,
        # the following line is a hack to ensure we have
        # access to the contents of @classpath.
        classpath = @classpath
        ant.path id: "classpath" do
          classpath.each do |path|
            fileset dir: path
          end
        end

        ant.javac srcdir:     @source.to_s,
          destdir:            @target.to_s,
          debug:              "yes",
          includeantruntime:  "no",
          classpathref:       "classpath"
      end

      if add_target_to_current_classpath
        target_url = java.io.File.new(@target.expand_path.to_s.ensure_ends_with("/")).to_url.to_s
        $CLASSPATH << target_url unless $CLASSPATH.include?(target_url)
      end

      self
    end

  end # class Compiler
end # class Doubleshot