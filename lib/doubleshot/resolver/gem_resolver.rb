class Doubleshot
  class Resolver
    class GemResolver < Resolver
      DEFAULT_REPOSITORY = "http://rubygems.org"

      def initialize(*repositories)
        super
        @graph = Graph.new(*repositories)
      end

      def resolve!(dependencies)
        demands = dependencies.map do |dependency|
          if dependency.requirements.empty?
            dependency.name
          else
            [ dependency.name, *dependency.requirements.map { |requirement| requirement.to_s } ]
          end
        end

        ui = Class.new do
          def say(*args)
            STDERR.puts *args
          end
        end.new
        ui = nil
        results = Solver.new(@graph, demands, ui).resolve

        results.each_pair do |name, version|
          dependencies.fetch(name).lock(version)
        end

        dependencies
      end

    end
  end
end

require "doubleshot/resolver/gem_resolver/source"
require "doubleshot/resolver/gem_resolver/artifact"
require "doubleshot/resolver/gem_resolver/demand"
require "doubleshot/resolver/gem_resolver/dependency"
require "doubleshot/resolver/gem_resolver/errors"
require "doubleshot/resolver/gem_resolver/graph"
require "doubleshot/resolver/gem_resolver/solver"