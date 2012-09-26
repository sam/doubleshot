class Doubleshot
  class Dependencies
    class Dependency
      attr_reader :name

      def initialize(name, version = nil)
        @name = name.dup.freeze
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

      def eql?(other)
        other.is_a?(Dependency) and other.name == @name
      end

      def hash
        @hash ||= @name.hash
      end

      def ==(other)
        eql?(other) && requirements == other.requirements
      end
    end
  end
end