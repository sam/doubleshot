class Doubleshot
  class Resolver
    class GemResolver
      class Artifact
        include Comparable

        # A reference to the graph this artifact belongs to
        #
        # @return [Doubleshot::Resolver::GemResolver::Graph]
        attr_reader :graph

        # The name of the artifact
        #
        # @return [String]
        attr_reader :name

        # The version of this artifact
        #
        # @return [Gem::Version]
        attr_reader :version

        # @param [Doubleshot::Resolver::GemResolver::Graph] graph
        # @param [#to_s] name
        # @param [Gem::Version, #to_s] version
        def initialize(graph, name, version)
          @graph = graph
          @name = name
          @version = Gem::Version.new(version)
          @dependencies = Hash.new
        end

        # Return the Doubleshot::Resolver::GemResolver::Dependency from the collection of
        # dependencies with the given name and constraint.
        #
        # @param [#to_s] name
        # @param [Gem::Requirement, #to_s] constraint
        #
        # @example adding dependencies
        #   artifact.depends("nginx") => <#Dependency: @name="nginx", @constraint=">= 0.0.0">
        #   artifact.depends("ntp", "= 1.0.0") => <#Dependency: @name="ntp", @constraint="= 1.0.0">
        #
        # @example chaining dependencies
        #   artifact.depends("nginx").depends("ntp")
        #
        # @return [Doubleshot::Resolver::GemResolver::Artifact]
        def depends(name, constraint = ">= 0")
          if name.nil?
            raise ArgumentError, "A name must be specified. You gave: #{args}."
          end

          dependency = Dependency.new(self, name, constraint)
          add_dependency(dependency)

          self
        end

        # Return the collection of dependencies on this instance of artifact
        #
        # @return [Array<Doubleshot::Resolver::GemResolver::Dependency>]
        def dependencies
          @dependencies.collect { |name, dependency| dependency }
        end

        # Retrieve the dependency from the artifact with the matching name and constraint
        #
        # @param [#to_s] name
        # @param [#to_s] constraint
        #
        # @return [Doubleshot::Resolver::GemResolver::Artifact, nil]
        def get_dependency(name, constraint)
          @dependencies.fetch(Graph.dependency_key(name, constraint), nil)
        end

        # Remove this artifact from the graph it belongs to
        #
        # @return [Doubleshot::Resolver::GemResolver::Artifact, nil]
        def delete
          unless graph.nil?
            result = graph.remove_artifact(self)
            @graph = nil
            result
          end
        end

        def to_s
          "#{name}-#{version}"
        end

        # @param [Object] other
        #
        # @return [Boolean]
        def ==(other)
          other.is_a?(self.class) &&
            self.name == other.name &&
            self.version == other.version
        end
        alias_method :eql?, :==

        # @param [Gem::Version] other
        #
        # @return [Integer]
        def <=>(other)
          self.version <=> other.version
        end

        private

        # Add a Doubleshot::Resolver::GemResolver::Dependency to the collection of dependencies
        # and return the added Doubleshot::Resolver::GemResolver::Dependency. No change will be
        # made if the dependency is already a member of the collection.
        #
        # @param [Doubleshot::Resolver::GemResolver::Dependency] dependency
        #
        # @return [Doubleshot::Resolver::GemResolver::Dependency]
        def add_dependency(dependency)
          unless has_dependency?(dependency.name, dependency.constraint)
            @dependencies[Graph.key_for(dependency)] = dependency
          end

          get_dependency(dependency.name, dependency.constraint)
        end

        # Remove the matching dependency from the artifact
        #
        # @param [Doubleshot::Resolver::GemResolver::Dependency] dependency
        #
        # @return [Doubleshot::Resolver::GemResolver::Dependency, nil]
        def remove_dependency(dependency)
          if has_dependency?(dependency)
            @dependencies.delete(Graph.key_for(dependency))
          end
        end

        # Check if the artifact has a dependency with the matching name and constraint
        #
        # @param [#to_s] name
        # @param [#to_s] constraint
        #
        # @return [Boolean]
        def has_dependency?(name, constraint)
          @dependencies.has_key?(Graph.dependency_key(name, constraint))
        end
      end
    end
  end
end