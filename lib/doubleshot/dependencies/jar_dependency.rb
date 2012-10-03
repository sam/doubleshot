require "doubleshot/dependencies/dependency"

class Doubleshot
  class Dependencies
    class JarDependency < Dependency
      attr_reader :group, :artifact, :type, :version

      def initialize(name)
        @name = name
        @group, @artifact, @type, @version = name.split(":")
        if @group.blank? or @artifact.blank? or @type.blank? or @version.blank?
          raise ArgumentError.new(%q<+name+ must be a String with the format "groupId:artifactId:packageType:version" (http://buildr.apache.org/quick_start.html#dependencies)>)
        end
      end
    end
  end
end
