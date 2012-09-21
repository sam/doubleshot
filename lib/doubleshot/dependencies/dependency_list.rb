class Doubleshot
  class Dependencies
    class DependencyList
      include Enumerable
      
      def initialize
        @dependencies = []
      end

      def add(dependency)
        unless dependency.is_a? Dependency
          raise ArgumentError.new("+dependency+ must be a Doubleshot::Dependencies::Dependency")
        end
        @dependencies << dependency
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