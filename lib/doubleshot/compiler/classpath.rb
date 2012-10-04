require "set"

class Doubleshot
  class Compiler
    class Classpath

      include Enumerable

      def initialize
        @set = Set.new
      end

      def add(path)
        path = Pathname(path.to_s)
        
        if path.directory?
          @set << path
        elsif path.file?
          @set << path.dirname
        else
          raise Errno::ENOENT.new(path.expand_path.to_s)
        end

        self
      end

      def size
        @set.size
      end
      alias :length :size 

      def each
        @set.each { |entry| yield entry }
      end
    end
  end
end