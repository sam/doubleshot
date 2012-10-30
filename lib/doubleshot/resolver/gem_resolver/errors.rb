class Doubleshot
  class Resolver
    class GemResolver
      module Errors
        class Doubleshot::Resolver::GemResolverError < StandardError; end

        class InvalidVersionFormat < Doubleshot::Resolver::GemResolverError
          attr_reader :version

          # @param [#to_s] version
          def initialize(version)
            @version = version
          end

          def message
            "'#{version}' did not contain a valid version string: 'x.y.z' or 'x.y'."
          end
        end

        class InvalidConstraintFormat < Doubleshot::Resolver::GemResolverError
          attr_reader :constraint

          # @param [#to_s] constraint
          def initialize(constraint)
            @constraint = constraint
          end

          def message
            "'#{constraint}' did not contain a valid operator or a valid version string."
          end
        end

        class NoSolutionError < Doubleshot::Resolver::GemResolverError; end
      end
    end
  end
end
