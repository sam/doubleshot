class Doubleshot
  class Configuration
    class SourceLocations

      def initialize
        @ruby   = Pathname("lib")
        @java   = Pathname("ext/java")
        @tests  = Pathname("test")
      end

      attr_reader :ruby
      def ruby=(path)
        @ruby = validate_path(path)
      end

      attr_reader :java
      def java=(path)
        @java = validate_path(path)
      end

      attr_reader :tests
      def tests=(path)
        @tests = validate_path(path)
      end

      def eql?(other)
        other.is_a?(self.class) &&
          other.ruby == ruby &&
          other.java == java &&
          other.tests == tests
      end
      alias :== :eql?

      private
      def validate_path(path)
        check = Pathname(path.to_s)

        unless check.directory?
          raise IOError.new("+path+ must be a directory but was #{path.inspect}")
        end

        check
      end
    end
  end
end