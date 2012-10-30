class Doubleshot
  class Resolver
    class GemResolver
      class Demand
        # A reference to the solver this demand belongs to
        #
        # @return [Doubleshot::Resolver::GemResolver::Solver]
        attr_reader :solver

        # The name of the artifact this demand is for
        #
        # @return [String]
        attr_reader :name

        # The acceptable constraint of the artifact this demand is for
        #
        # @return [Gem::Requirement]
        attr_reader :constraint

        # @param [Doubleshot::Resolver::GemResolver::Solver] solver
        # @param [#to_s] name
        # @param [Gem::Requirement, #to_s] constraint
        def initialize(solver, name, constraint = ">= 0")
          @solver = solver
          @name = name
          @constraint = if constraint.is_a?(Gem::Requirement)
            constraint
          else
            Gem::Requirement.new(constraint.to_s)
          end
        end

        # Remove this demand from the solver it belongs to
        #
        # @return [Doubleshot::Resolver::GemResolver::Demand, nil]
        def delete
          unless solver.nil?
            result = solver.remove_demand(self)
            @solver = nil
            result
          end
        end

        def to_s
          "#{name} (#{constraint})"
        end

        def ==(other)
          other.is_a?(self.class) &&
            self.name == other.name &&
            self.constraint == other.constraint
        end
        alias_method :eql?, :==
      end
    end
  end
end
