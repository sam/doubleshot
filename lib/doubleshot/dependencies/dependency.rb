class Doubleshot
  class Dependencies
    class Dependency
      attr_accessor :name

      def initialize(name, version = nil)
        @name = name
        @version = version
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
    end
  end
end
