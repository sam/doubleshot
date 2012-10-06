require "doubleshot/dependencies/dependency"

class Doubleshot
  class Dependencies
    class GemDependency < Dependency

      def initialize(name)
        super
        @requirements = Set.new
      end

      def requirements
        ReadonlyCollection.new(@requirements)
      end

      def add_requirement(requirement)
        requirement = Gem::Requirement.new(requirement)
        @requirements << requirement
        requirement
      end

      def ==(other)
        eql?(other) && requirements == other.requirements
      end

      def to_s(long_form = false)
        if long_form && !@requirements.empty?
          "#{name} (#{@requirements.sort.map(&:to_s).join(", ")})"
        else
          @name
        end
      end

      # def gemspec
      # end

      # def dependencies
      #   #gemspec.runtime_dependencies
      # end

    end
  end
end