class Doubleshot
  class Resolver
    class JarResolver < Resolver
      DEFAULT_REPOSITORY = "http://repo1.maven.org/maven2"

      def initialize(*repositories)
        super
        # Change the second argument to "true" to get verbose output.
        @aether = org.sam.doubleshot.Aether.new(Pathname("~/.m2").expand_path.to_s, false, false)
        @repositories.each do |repository|
          @aether.add_repository repository.host, repository.to_s
        end
      end

      def resolve!(dependencies)
        dependencies.each do |dependency|
          @aether.add_artifact dependency.to_s
        end

        @aether.resolve
        classpath_map = @aether.classpath_map

        @aether.resolved_coordinates.each do |coordinate|
          dependencies.add Dependencies::JarDependency.new coordinate
        end

        dependencies.each do |dependency|
          dependency.path = classpath_map[dependency.to_s]
        end
        dependencies
      end
    end
  end
end