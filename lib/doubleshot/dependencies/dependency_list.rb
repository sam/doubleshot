require "doubleshot/dependencies/dependency"

class Doubleshot
  class Dependencies
    class DependencyList
      include Enumerable

      DEPENDENCY_CLASS = Dependency

      def initialize
        @dependencies = Set.new
      end

      def eql?(other)
        other.is_a?(self.class) && entries == other.entries
      end
      alias :== :eql?

      def add(dependency)
        unless dependency.is_a? Dependency
          raise ArgumentError.new("+dependency+ must be a Doubleshot::Dependencies::Dependency")
        end
        @dependencies << dependency
        self
      end

      def fetch(name)
        raise ArgumentError.new("+name+ must be a String") unless name.is_a? String

        unless dependency = @dependencies.detect { |entry| entry.name == name }
          dependency = self.class::DEPENDENCY_CLASS.new(name)
          add dependency
        end

        dependency
      end

      def size
        @dependencies.size
      end
      alias :length :size

      def empty?
        @dependencies.empty?
      end

      def each
        @dependencies.each do |dependency|
          yield dependency
        end
      end

      def include?(dependency)
        if dependency.is_a? Dependency
          @dependencies.include? dependency
        elsif dependency.is_a? String
          @dependencies.any? { |entry| entry.name == dependency }
        else
          raise ArgumentError.new("+dependency+ must be a Doubleshot::Dependencies::Dependency or a String")
        end
      end
    end
  end
end
