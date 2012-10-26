require "forwardable"

class Doubleshot
  class Resolver
    class GemResolver
      class Solver
        class ConstraintRow
          extend Forwardable

          attr_reader :source

          def_delegator :dependency, :name
          def_delegator :dependency, :constraint

          # @param [Doubleshot::Resolver::GemResolver::Dependency] dependency
          # @param [String, Symbol] source
          def initialize(dependency, source)
            @dependency = dependency
            @source = source
          end

          private

            attr_reader :dependency
        end
      end
    end
  end
end
