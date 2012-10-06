java_import "org.sam.doubleshot.Aether"

class Doubleshot
  class Resolver
    class JarResolver < Resolver
      DEFAULT_REPOSITORY = "http://repo1.maven.org/maven2"

      def initialize(*repositories)
        super
        @aether = Aether.new(Pathname("~/.m2").to_s, false, false)
      end

      def fetch(dependencies)
        dependencies
      end
    end
  end
end