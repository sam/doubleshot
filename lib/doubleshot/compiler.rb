require "java"
require "ant"

class Doubleshot
  class Compiler

    def initialize(source, target)
      @source = Pathname(source.to_s)
      @target = Pathname(target.to_s)
    end

    attr_reader :source, :target

    def build!
      @target.mkdir unless @target.exist?
      
      # The JRuby ant integration throws JRuby Persistence
      # warnings that you can't supress, so we run it
      # inside of a Kernel#silence block.
      silence do
        ant.path id: "classpath" do  
          fileset dir: @target.to_s

          $CLASSPATH.map do |path|
            Pathname path.to_s.gsub(/file\:/, "")
          end.select do |path|
            path.exist?
          end.map do |path|
            (path.directory? ? path : path.dirname).to_s.ensure_ends_with("/")
          end.uniq.each do |path|
            fileset dir: path
          end
        end

        ant.javac srcdir:     @source.to_s,
          destdir:            @target.to_s,
          debug:              "yes",
          includeantruntime:  "no",
          classpathref:       "classpath"
      end

      $CLASSPATH << @target.to_s unless $CLASSPATH.include?(@target.to_s)
    end

  end # class Compiler
end # class Doubleshot