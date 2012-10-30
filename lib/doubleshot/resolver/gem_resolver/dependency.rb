class Doubleshot
  class Resolver
    class GemResolver
      class Dependency
        # A reference to the artifact this dependency belongs to
        #
        # @return [Doubleshot::Resolver::GemResolver::Artifact]
        attr_reader :artifact

        # The name of the artifact this dependency represents
        #
        # @return [String]
        attr_reader :name

        # The constraint requirement of this dependency
        #
        # @return [Gem::Requirement]
        attr_reader :constraint

        # @param [Doubleshot::Resolver::GemResolver::Artifact] artifact
        # @param [#to_s] name
        # @param [Gem::Requirement, #to_s] constraint
        def initialize(artifact, name, constraint = ">= 0")
          @artifact = artifact
          @name = name
          @constraint = case constraint
          when Gem::Requirement
            constraint
          else
            Gem::Requirement.new(constraint)
          end
        end

        # Remove this dependency from the artifact it belongs to
        #
        # @return [Doubleshot::Resolver::GemResolver::Dependency, nil]
        def delete
          unless artifact.nil?
            result = artifact.remove_dependency(self)
            @artifact = nil
            result
          end
        end

        # @param [Object] other
        #
        # @return [Boolean]
        def ==(other)
          other.is_a?(self.class) &&
            self.artifact == other.artifact &&
            self.constraint == other.constraint
        end
        alias_method :eql?, :==
      end
    end
  end
end
