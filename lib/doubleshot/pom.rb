class Doubleshot
  class Pom
    def initialize(config)
      @config = config
    end

    def to_s
      jars = @config.runtime.jars + @config.development.jars

      <<-EOS.margin
        <?xml version="1.0"?>
        <project xmlns="http://maven.apache.org/POM/4.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
          <modelVersion>4.0.0</modelVersion>
          <groupId>#{@config.group}</groupId>
          <artifactId>#{@config.project}</artifactId>
          <version>#{@config.version}</version>
          <packaging>pom</packaging>
          <name>#{@config.project}</name>
          #{
            unless jars.empty?
              "<dependencies>\n            " +
              jars.map do |jar|
                <<-JAR.strip
            <dependency>
              <groupId>#{jar.group}</groupId>
              <artifactId>#{jar.artifact}</artifactId>
              <version>#{jar.version}</version>
              <type>#{jar.type}</type>
            </dependency>
                JAR
              end.join("\n            ") +
              "\n          </dependencies>\n"
            end
          }        </project>
      EOS
    end
  end
end