class Doubleshot
  class Resolver
    class GemResolver < Resolver
      DEFAULT_REPOSITORY = "http://rubygems.org"

      def initialize(*repositories)
        super
        @sources = repositories.map do |repository|
          Source.new(repository)
        end
      end

      class MissingGemError < Gem::GemNotFoundException
        def initialize(dependency)
          super "No Gem found for #{dependency.inspect}", dependency.name, dependency.version
        end
      end

      def resolve!(dependencies)

        graph = Set.new

        dependencies.each do |dependency|

          versions = {}

          @sources.each do |source|
            source.versions(dependency.name).each do |version|
              version = Gem::Version.new(version)
              if dependency.requirements.all? { |requirement| requirement.satisfied_by? version }
                versions[version] ||= source
              end
            end
          end

          if versions.empty?
            raise MissingGemError.new(dependency)
          else
            latest_version = versions.keys.max
            source = versions[latest_version]
            gemspec = source.spec dependency.name, latest_version

            graph.add dependency

            gemspec.runtime_dependencies.each do |runtime_dependency|
              nested_dependency = Dependencies::GemDependency.new runtime_dependency.name
              runtime_dependency.requirements_list.each do |requirement|
                nested_dependency.add_requirement requirement.to_s
              end
              graph.add nested_dependency
            end
          end
        end

        graph.each { |dependency| dependencies.add dependency }
        dependencies
      end

    end
  end
end

require "doubleshot/resolver/gem_resolver/source"