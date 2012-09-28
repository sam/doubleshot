class Doubleshot
  class Configuration
    class SourceLocations

      def initialize
        @defaults  = {}
        @ruby      = default :ruby, Pathname("lib")
        @java      = default :java, Pathname("ext/java")
        @tests     = default :tests, Pathname("test")
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

      def __changes__
        changes = []
        @defaults.each_pair do |key,value|
          changes << key unless instance_variable_get("@#{key}") == value
        end
        changes
      end

      private
      def validate_path(path)
        check = Pathname(path.to_s)

        unless check.directory?
          raise IOError.new("+path+ must be a directory but was #{path.inspect}")
        end

        check
      end

      def default(key, value)
        @defaults[key] = value
      end
    end
  end
end