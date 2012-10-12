require "doubleshot/dependencies/dependency"

class Doubleshot
  class Dependencies
    class JarDependency < Dependency

      PACKAGE_TYPES = [ "pom", "jar", "maven-plugin", "ejb", "war", "ear", "rar", "par", "bundle" ]

      attr_reader :group, :artifact, :packaging, :classifier, :version
      attr_accessor :path

      def initialize(maven_coordinate)
        # @name = maven_coordinate
        maven_coordinate_parts = maven_coordinate.split(":")

        # if maven_coordinate
        # [ "org.example", "doubleshot", "jar"].each_with_index do |part, i|
        #   case i
        #   when 0 then @group = part
        #   when 1 then @artifact = part
        #   when 2 then
        #     if PACKAGE_TYPES.include? part.downcase
        #       @packaging = part.downcase
        #     else
        #       @version = part
        #     end
        #   when 3 then
        #     if @version.blank?
        #       @version = part
        #     else
        #       raise ArgumentError.new("Invalid coordinate")
        #     end
        #   end
        # end
        #
        # raise ArgumentError.new("Invalid coordinate, version must not be blank: #{maven_coordinate.inspect}") if @version.blank?

        # alternative
        @group = maven_coordinate_parts.shift
        @artifact = maven_coordinate_parts.shift
        @version = maven_coordinate_parts.pop
        packaging, @classifier = *maven_coordinate_parts

        raise ArgumentError.new("Invalid coordinate (version must not be blank): #{maven_coordinate.inspect}") if @version.blank?

        @name = "#{@group}:#{@artifact}:#{@packaging}#{":#{@classifier}" if @classifier}:#{@version}"

        # @group, @artifact, @type, @version = name.split(":")
        # if @group.blank? or @artifact.blank? or @type.blank? or @version.blank?
        #   raise ArgumentError.new(%q<+name+ must be a String with the format "groupId:artifactId:packageType:version" (http://buildr.apache.org/quick_start.html#dependencies)>)
        # end
      end

      def to_s(long_form = false)
        @name
      end

      private

      def packaging=(value = "jar")
        if PACKAGE_TYPES.include?(value.downcase)
          @packaging = value.downcase
        else
          raise ArgumentError.new("Invalid Packaging Type: #{value.inspect}")
        end
      end

      def version=(value)
        @version = value

        # compare version against rules specified here: http://www.sonatype.com/books/mvnref-book/reference/pom-relationships-sect-pom-syntax.html#pom-relationships-sect-version-build-numbers
        # http://stackoverflow.com/questions/30571/how-do-i-tell-maven-to-use-the-latest-version-of-a-dependency
      end
    end
  end
end
