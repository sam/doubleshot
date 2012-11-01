require "doubleshot/resolver/gem_resolver/solver/constraint_row"
require "doubleshot/resolver/gem_resolver/solver/constraint_table"
require "doubleshot/resolver/gem_resolver/solver/variable_row"
require "doubleshot/resolver/gem_resolver/solver/variable_table"

class Doubleshot
  class Resolver
    class GemResolver
      class Solver
        class << self
          # Create a key to identify a demand on a Doubleshot::Resolver::GemResolver::Solver.
          #
          # @param [Doubleshot::Resolver::GemResolver::Demand] demand
          #
          # @raise [NoSolutionError]
          #
          # @return [Symbol]
          def demand_key(demand)
            "#{demand.name}-#{demand.constraint}".to_sym
          end

          # Returns all of the versions which satisfy all of the given constraints
          #
          # @param [Array<Gem::Requirement>, Array<String>] constraints
          # @param [Array<Gem::Version>, Array<String>] versions
          #
          # @return [Array<Gem::Version>]
          def satisfy_all(constraints, versions)
            constraints = Array(constraints).collect do |con|
              con.is_a?(Gem::Requirement) ? con : Gem::Requirement.new(con.to_s)
            end.uniq

            versions = Array(versions).collect do |ver|
              ver.is_a?(Gem::Version) ? ver : Gem::Version.new(ver.to_s)
            end.uniq

            versions.select do |ver|
              constraints.all? { |constraint| constraint.satisfied_by?(ver) }
            end
          end

          # Return the best version from the given list of versions for the given list of constraints
          #
          # @param [Array<Gem::Requirement>, Array<String>] constraints
          # @param [Array<Gem::Version>, Array<String>] versions
          #
          # @raise [NoSolutionError] if version matches the given constraints
          #
          # @return [Gem::Version]
          def satisfy_best(constraints, versions)
            solution = satisfy_all(constraints, versions)

            if solution.empty?
              raise Errors::NoSolutionError
            end

            solution.sort.last
          end
        end

        # The world as we know it
        #
        # @return [Doubleshot::Resolver::GemResolver::Graph]
        attr_reader :graph
        attr_reader :demands
        attr_reader :ui

        attr_reader :domain
        attr_reader :variable_table
        attr_reader :constraint_table
        attr_reader :possible_values

        # @param [Doubleshot::Resolver::GemResolver::Graph] graph
        # @param [Array<String>, Array<Array<String, String>>] demands
        # @param [#say] ui
        def initialize(graph, demands = Array.new, ui=nil)
          @graph = graph
          @demands = Hash.new
          @ui = ui.respond_to?(:say) ? ui : nil

          @domain = Hash.new
          @possible_values = Hash.new
          @constraint_table = ConstraintTable.new
          @variable_table = VariableTable.new

          Array(demands).each do |l_demand|
            demands(*l_demand)
          end
        end

        # @return [Hash]
        def resolve
          trace("Attempting to find a solution")
          seed_demand_dependencies

          while unbound_variable = variable_table.first_unbound
            possible_values_for_unbound = possible_values_for(unbound_variable)
            trace("Searching for a value for #{unbound_variable.artifact}")
            trace("Constraints are")
            constraint_table.constraints_on_artifact(unbound_variable.artifact).each do |constraint|
              trace("\t#{constraint}")
            end
            trace("Possible values are #{possible_values_for_unbound}")

            while possible_value = possible_values_for_unbound.shift
              possible_artifact = graph.get_artifact(unbound_variable.artifact, possible_value.version)
              possible_dependencies = possible_artifact.dependencies
              all_ok = possible_dependencies.all? { |dependency| can_add_new_constraint?(dependency) }
              if all_ok
                trace("Attempting to use #{possible_artifact}")
                add_dependencies(possible_dependencies, possible_artifact)
                unbound_variable.bind(possible_value)
                break
              end
            end

            unless unbound_variable.bound?
              trace("Could not find an acceptable value for #{unbound_variable.artifact}")
              backtrack(unbound_variable)
            end
          end

          solution = {}.tap do |solution|
            variable_table.rows.each do |variable|
              solution[variable.artifact] = variable.value.version.to_s
            end
          end

          trace("Found Solution")
          trace(solution)

          solution
        end

        # @overload demands(name, constraint)
        #   Return the Doubleshot::Resolver::GemResolver::Demand from the collection of demands
        #   with the given name and constraint.
        #
        #   @param [#to_s]
        #   @param [Gem::Requirement, #to_s]
        #
        #   @return [Doubleshot::Resolver::GemResolver::Demand]
        # @overload demands(name)
        #   Return the Doubleshot::Resolver::GemResolver::Demand from the collection of demands
        #   with the given name.
        #
        #   @param [#to_s]
        #
        #   @return [Doubleshot::Resolver::GemResolver::Demand]
        # @overload demands
        #   Return the collection of demands
        #
        #   @return [Array<Doubleshot::Resolver::GemResolver::Demand>]
        def demands(*args)
          if args.empty?
            return demand_collection
          end
          if args.length > 2
            raise ArgumentError, "Unexpected number of arguments. You gave: #{args.length}. Expected: 2 or less."
          end

          name, constraint = args
          constraint ||= ">= 0"

          if name.nil?
            raise ArgumentError, "A name must be specified. You gave: #{args}."
          end

          demand = Demand.new(self, name, constraint)
          add_demand(demand)
        end

        # Add a Doubleshot::Resolver::GemResolver::Demand to the collection of demands and
        # return the added Doubleshot::Resolver::GemResolver::Demand. No change will be made
        # if the demand is already a member of the collection.
        #
        # @param [Doubleshot::Resolver::GemResolver::Demand] demand
        #
        # @return [Doubleshot::Resolver::GemResolver::Demand]
        def add_demand(demand)
          unless has_demand?(demand)
            @demands[self.class.demand_key(demand)] = demand
          end

          demand
        end
        alias_method :demand, :add_demand

        # @param [Doubleshot::Resolver::GemResolver::Demand, nil] demand
        def remove_demand(demand)
          if has_demand?(demand)
            @demands.delete(self.class.demand_key(demand))
          end
        end

        # @param [Doubleshot::Resolver::GemResolver::Demand] demand
        #
        # @return [Boolean]
        def has_demand?(demand)
          @demands.has_key?(self.class.demand_key(demand))
        end

        private

          # @return [Array<Doubleshot::Resolver::GemResolver::Demand>]
          def demand_collection
            @demands.collect { |name, demand| demand }
          end

          def seed_demand_dependencies
            add_dependencies(demands, :root)
          end

          def can_add_new_constraint?(dependency)
            current_binding = variable_table.find_artifact(dependency.name)
            #haven't seen it before, haven't bound it yet or the binding is ok
            current_binding.nil? || current_binding.value.nil? || dependency.constraint.satisfied_by?(current_binding.value.version)
          end

          def possible_values_for(variable)
            possible_values_for_variable = possible_values[variable.artifact]
            if possible_values_for_variable.nil?
              constraints_for_variable = constraint_table.constraints_on_artifact(variable.artifact)
              all_values_for_variable = domain[variable.artifact]
              possible_values_for_variable = constraints_for_variable.inject(all_values_for_variable) do |remaining_values, constraint|
                remaining_values.reject { |value| !constraint.satisfied_by?(value.version) }
              end
              possible_values[variable.artifact] = possible_values_for_variable
            end
            possible_values_for_variable
          end

          def add_dependencies(dependencies, source)
            dependencies.each do |dependency|
              trace("Adding constraint #{dependency.name} #{dependency.constraint} from #{source}")
              variable_table.add(dependency.name, source)
              constraint_table.add(dependency, source)
              dependency_domain = graph.versions(dependency.name, dependency.constraint)
              domain[dependency.name] = [(domain[dependency.name] || []), dependency_domain]
              .flatten
              .uniq
              .sort { |left, right| right.version <=> left.version }

              #if the variable we are constraining is still unbound, we want to filter
              #its possible values, if its already bound, we know its ok to add this constraint because
              #we can never change a previously bound value without removing this constraint and we check above
              #whether or not its ok to add this constraint given the current value

              variable = variable_table.find_artifact(dependency.name)
              if variable.value.nil?
                reset_possible_values_for(variable)
              end
            end
          end

          def reset_possible_values_for(variable)
            possible_values[variable.artifact] = nil
            possible_values_for(variable)
          end

          def backtrack(unbound_variable)
            previous_variable = variable_table.before(unbound_variable.artifact)

            if previous_variable.nil?
              trace("Cannot backtrack any further")
              raise Errors::NoSolutionError
            end

            trace("Unbinding #{previous_variable.artifact}")

            source = previous_variable.value
            removed_variables = variable_table.remove_all_with_only_this_source!(source)
            removed_variables.each do |removed_variable|
              possible_values[removed_variable.artifact] = nil
              trace("Removed variable #{removed_variable.artifact}")
            end
            removed_constraints = constraint_table.remove_constraints_from_source!(source)
            removed_constraints.each do |removed_constraint|
              trace("Removed constraint #{removed_constraint.name} #{removed_constraint.constraint}")
            end
            previous_variable.unbind
            variable_table.all_after(previous_variable.artifact).each do |variable|
              new_possibles = reset_possible_values_for(variable)
            end
          end

          def trace(message)
            ui.say(message) unless ui.nil?
          end
      end
    end
  end
end
