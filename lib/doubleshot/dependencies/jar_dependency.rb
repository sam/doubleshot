require "doubleshot/dependencies/dependency"

class Doubleshot
  class Dependencies
    class JarDependency < Dependency
      attr_reader :group, :artifact, :type, :version
      attr_accessor :path

      def initialize(name)
        @name = name
        @group, @artifact, @type, @version = name.split(":")
        if @group.blank? or @artifact.blank? or @type.blank? or @version.blank?
          raise ArgumentError.new(%q<+name+ must be a String with the format "groupId:artifactId:packageType:version" (http://buildr.apache.org/quick_start.html#dependencies)>)
        end
      end

      def to_s(long_form = false)
        @name
      end
    end
  end
end
