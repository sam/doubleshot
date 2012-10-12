require "set"

class Doubleshot
  class Compiler
    class Classpath

      include Enumerable

      def initialize
        @set = Set.new
      end

      def add(path)
        path = Pathname(path.to_s).expand_path

        if path.directory?
          @set << path
        elsif path.file?
          @set << path.dirname
        else
          raise ArgumentError.new("+path+ must be a file or directory with read permission: #{path}")
        end

        self
      end
      alias :<< :add

      def size
        @set.size
      end
      alias :length :size

      def empty?
       @set.empty?
      end

      def each
        @set.each { |entry| yield entry }
      end

      def to_s
        "CLASSPATH: #{@set.entries.sort.join(", ")}"
      end
    end
  end
end
