require "doubleshot/dependencies"
require "doubleshot/configuration/source_locations"

class Doubleshot
  class Configuration

    DEFAULT_PATHS = [ "Doubleshot", "*LICENSE*", "README*" ]
    DEFAULT_WHITELIST = %w[
      .rb .java .js
      .yaml .yml .json .xml .properties
      .css .less .sass .scss
      .erb .haml .rxml .builder .html
    ]

    PROJECT_MESSAGE       = <<-EOS.margin
    # The project name will be used as your JAR's
    # artifactId and your Gem's name.
    EOS

    GROUP_MESSAGE         = <<-EOS.margin
    # The groupId of your JAR. This will default to
    # the project name if not supplied.
    #
    # NOTE: You are strongly encouraged to set this
    # to something meaningful if you are planning to
    # package your project as a JAR.
    EOS

    VERSION_MESSAGE       = <<-EOS.margin
    # Version number that obeys the constraints of
    # Gem::Version:
    #
    #   If any part contains letters, then the version
    #     is considered pre-release.
    EOS

    GEM_REPOSITORY_MESSAGE = <<-EOS.margin
    # Add your custom ruby gem repositories here.
    #
    # Default is http://rubygems.org
    # (defined in Resolver::GemResolver::DEFAULT_REPOSITORY)
    EOS

    MVN_REPOSITORY_MESSAGE = <<-EOS.margin
    # Add your custom Maven repositories here.
    #
    # Default is http://repo1.maven.org/maven2
    # (defined in Resolver::JarResolver::DEFAULT_REPOSITORY)
    EOS

    SOURCE_RUBY_MESSAGE   = <<-EOS.margin
    # Relative path to the folder containing your
    # Ruby source code (.rb files).
    # The default is "lib".
    EOS

    SOURCE_JAVA_MESSAGE   = <<-EOS.margin
    # Relative path to the folder containing your
    # Java source code (.java files).
    # The default is "ext/java".
    EOS

    SOURCE_TESTS_MESSAGE  = <<-EOS.margin
    # Relative path to the folder containing your
    # tests. This feature is used when running
    #   doubleshot test
    # Tests are assumed to be written in Ruby
    # exclusively. Java test frameworks are not
    # supported.
    # This value is optional. The default is "test".
    EOS

    TARGET_MESSAGE        = <<-EOS.margin
    # Relative path to the folder containing the
    # compiled Java files (.class files).
    # The default is "target".
    EOS

    JAVA_MAIN_MESSAGE     = <<-EOS.margin
    # Class to use for Ant's Main-Class attribute for
    # a manifest. The default is "org.jruby.Main".
    EOS

    WHITELIST_MESSAGE     = <<-EOS.margin
    # List of file extensions within source folders
    # that will be included during packaging.
    # Does NOT override defaults, but adds to them.
    # The default list can be found in
    # Doubleshot::Configuration::DEFAULT_WHITELIST.
    EOS


    GEMSPEC_MESSAGE       = <<-EOS.margin
    # A subset of Gem::Specification compatible
    # with Doubleshot. Since Doubleshot manages
    # your Rubygems dependencies, and what files
    # are included in your build, those options
    # are not applicable (and will be discarded if
    # provided).
    EOS

    GEM_DEPENDENCY_MESSAGE = <<-EOS.margin
    # Add your Gem dependencies here using similar
    # syntax to a gemspec, except your method is
    # "gem" instead of "add_runtime_dependency".
    EOS

    JAR_DEPENDENCY_MESSAGE = <<-EOS.margin
    # Add your JAR dependencies using Buildr
    # dependency formatting (available as a
    # copy-and-paste option on most Maven search
    # repositories).
    EOS

    DEVELOPMENT_MESSAGE = <<-EOS.margin
    # Add your Gem and JAR development dependencies
    # similar to above. By default "doubleshot" is
    # added as a development dependency to your gemspec.
    # That's the equivalent of:
    #
    #   config.development do
    #     config.gem "doubleshot"
    #   end
    #
    # NOTE: The above won't appear in your Doubleshot
    # file as it's added during the build process for you.
    EOS

    attr_accessor :java_main

    def initialize
      @defaults                    = {}
      @gemspec                     = Gem::Specification.new
      @gemspec.platform            = Gem::Platform.new("java")
      @source                      = SourceLocations.new
      @target                      = default :target, Pathname("target")
      @java_main                   = default :java_main, "org.jruby.Main"

      @runtime_dependencies        = Dependencies.new
      @development_dependencies    = Dependencies.new
      @development_environment     = false

      @paths                       = default :paths, DEFAULT_PATHS.dup
      @whitelist                   = default :whitelist, DEFAULT_WHITELIST.dup

      @project                     = default :project, "hello_world"
      @group                       = default :group, "org.world.hello"
      @version                     = default :version, "0.1"

      @gem_repositories            = default :gem_repositories, Set.new
      @mvn_repositories            = default :mvn_repositories, Set.new
    end

    def group
      @group || @project
    end

    def group=(name)
      @group = name
    end

    def project
      @project
    end

    def project=(name)
      @gemspec.name = name
      @project = name
      @group = default :group, @project unless __changes__.include? :group
      @project
    end

    def version
      @version
    end

    def version=(version)
      @gemspec.version = version
      @version = version
    end

    def gem_repository(uri)
      @gem_repositories << uri
      uri
    end

    def gem_repositories
      ReadonlyCollection.new(@gem_repositories.empty? ? [ Resolver::GemResolver::DEFAULT_REPOSITORY ] : @gem_repositories)
    end

    def mvn_repository(uri)
      @mvn_repositories << uri
      uri
    end

    def mvn_repositories
      ReadonlyCollection.new(@mvn_repositories.empty? ? [ Resolver::JarResolver::DEFAULT_REPOSITORY ] : @mvn_repositories)
    end

    def source
      @source
    end

    def target
      @target
    end

    def target=(path)
      @target = Pathname(path.to_s)
    end

    def whitelist(extname)
      @whitelist << extname.ensure_starts_with(".")
      self
    end

    def classpath
      @classpath
    end

    def classpath=(value)
      @classpath = value
    end

    def development
      if block_given?
        @development_environment = true
        yield
        @development_environment = false
      end
      @development_dependencies
    end

    def gem(name, *requirements)
      dependencies = @development_environment ?
        @development_dependencies :
        @runtime_dependencies

      dependency = dependencies.gems.fetch(name)
      dependencies.gems.add(dependency)

      requirements.each do |requirement|
        dependency.add_requirement(requirement)
      end

      dependency
    end

    def jar(coordinate)
      dependencies = @development_environment ?
        @development_dependencies :
        @runtime_dependencies

      dependency = dependencies.jars.fetch(coordinate)
      dependencies.jars.add(dependency)

      dependency
    end

    def runtime
      @runtime_dependencies
    end

    def paths
      ReadonlyCollection.new @paths
    end

    def add_path(path)
      @paths << path
      self
    end

    def eql?(other)
      other.is_a?(self.class) &&
        other.target       == target       &&
        other.source       == source       &&
        other.runtime      == runtime      &&
        other.development  == development  &&
        other.paths        == paths        &&
        other.gemspec      == gemspec
    end
    alias :== :eql?

    def gemspec(&b)
      if b
        yield @gemspec
      else
        @gemspec.rdoc_options = rdoc_options
        @gemspec.require_paths = [ @source.ruby.to_s, @target.to_s ]

        test_files = []
        if @source.tests.exist?
          @source.tests.find do |path|
            test_files << path.to_s if path.file? && @whitelist.include?(path.extname)
          end
        end
        @gemspec.test_files = test_files

        files = []

        @paths.each do |path|
          Pathname::glob(path).each do |match|
            files << match.to_s if match.file?
          end
        end

        if @source.ruby.exist?
          @source.ruby.find do |path|
            files << path.to_s if path.file? && @whitelist.include?(path.extname)
          end
        end

        if @source.java.exist?
          @source.java.find do |path|
            files << path.to_s if path.file? && @whitelist.include?(path.extname)
          end
        end

        if @target.exist?
          @target.find do |path|
            files << path.to_s if path.file? && path.extname != ".class"
          end
        end

        @gemspec.files.concat(files)

        @runtime_dependencies.gems.each do |dependency|
          @gemspec.add_runtime_dependency dependency.name, *dependency.requirements
        end

        @development_dependencies.gems.each do |dependency|
          @gemspec.add_development_dependency dependency.name, *dependency.requirements
        end

        bin = Pathname("bin").expand_path
        if bin.directory?
          bin.find do |path|
            @gemspec.executables << path.relative_path_from(bin).to_s if path.file? && path.executable?
          end
        end

        @gemspec.add_development_dependency "doubleshot"

        @gemspec
      end
    end

    def to_ruby
      <<-EOS.margin
        # encoding: utf-8

        Doubleshot.new do |config|
#{
            inner_heredoc = false
            to_ruby_body.split("\n").map do |line|
              output = if inner_heredoc
                "        #{line}"
              else
                "          #{line}"
              end

              if line =~ /\<\<\-DESCRIPTION/
                inner_heredoc = true
              elsif line =~ /^\s*DESCRIPTION/
                inner_heredoc = false
              end
              output
            end.join("\n")}
        end
      EOS
    end

    def to_ruby_body
      spec = gemspec

      config_changes = __changes__
      source_changes = @source.__changes__

      <<-EOS.margin
        #{Doubleshot::Configuration::PROJECT_MESSAGE}
        #{"#   " unless config_changes.include? :project}config.project = #{@project.inspect}

        #{Doubleshot::Configuration::GROUP_MESSAGE}
        #{"#   " unless config_changes.include? :group}config.group = #{@group.inspect}

        #{Doubleshot::Configuration::VERSION_MESSAGE}
        #{"#   " unless config_changes.include? :version}config.version = #{@version.to_s.inspect}


        #{Doubleshot::Configuration::GEM_REPOSITORY_MESSAGE}
        #{
          if config_changes.include? :gem_repositories
            (@gem_repositories).map do |repository|
              "config.gem_repository #{repository.inspect}"
            end.join("\n        ")
          else
            "#   config.gem_repository \"https://rubygems.org\"\n" +
            "#   config.gem_repository \"http://gems.example.com\""
          end
        }

        #{Doubleshot::Configuration::MVN_REPOSITORY_MESSAGE}
        #{
          if config_changes.include? :mvn_repositories
            (@mvn_repositories).map do |repository|
              "config.mvn_repository #{repository.inspect}"
            end.join("\n        ")
          else
            "#   config.mvn_repository \"http://repo1.maven.org/maven2\"\n" +
            "#   config.mvn_repository \"http://repository.jboss.com/maven2\""
          end
        }


        #{Doubleshot::Configuration::SOURCE_RUBY_MESSAGE}
        #{"#   " unless source_changes.include? :ruby}config.source.ruby    = #{@source.ruby.to_s.inspect}

        #{Doubleshot::Configuration::SOURCE_JAVA_MESSAGE}
        #{"#   " unless source_changes.include? :java}config.source.java    = #{@source.java.to_s.inspect}

        #{Doubleshot::Configuration::SOURCE_TESTS_MESSAGE}
        #{"#   " unless source_changes.include? :tests}config.source.tests   = #{@source.tests.to_s.inspect}


        #{Doubleshot::Configuration::TARGET_MESSAGE}
        #{"#   " unless config_changes.include? :target}config.target = #{@target.to_s.inspect}


        #{Doubleshot::Configuration::WHITELIST_MESSAGE}
        #{
          if config_changes.include? :whitelist
            (@whitelist - DEFAULT_WHITELIST).map do |ext|
              "config.whitelist #{ext.inspect}"
            end.join("\n        ")
          else
            "#   config.whitelist \".ext\""
          end
        }


        #{Doubleshot::Configuration::GEM_DEPENDENCY_MESSAGE}
        #{
          if @runtime_dependencies.gems.empty?
            "#   config.gem \"bcrypt-ruby\", \"~> 3.0\""
          else
            @runtime_dependencies.gems.map do |dependency|
              if dependency.requirements.empty?
                "config.gem \"#{dependency}\""
              else
                "config.gem \"#{dependency}\", \"#{dependency.requirements.map(&:to_s).join("\", \"")}\""
              end
            end.join("\n        ")
          end
        }

        #{Doubleshot::Configuration::JAR_DEPENDENCY_MESSAGE}
        #{
          if @runtime_dependencies.jars.empty?
            "#   config.jar \"ch.qos.logback:logback:jar:0.5\""
          else
            @runtime_dependencies.jars.map do |dependency|
              "config.jar \"#{dependency}\""
            end.join("\n        ")
          end
        }

        #{Doubleshot::Configuration::DEVELOPMENT_MESSAGE}
        #{
          unless @development_dependencies.empty?
            "config.development do\n        " +
            (
              @development_dependencies.gems.map do |dependency|
                if dependency.requirements.empty?
                  "  config.gem \"#{dependency}\""
                else
                  "  config.gem \"#{dependency}\", \"#{dependency.requirements.map(&:to_s).join("\", \"")}\""
                end
              end +
            @development_dependencies.jars.map do |dependency|
                "  config.jar \"#{dependency}\""
            end
            ).join("\n        ") + "\n        end"
          end
        }

        #{Doubleshot::Configuration::GEMSPEC_MESSAGE}
        config.gemspec do |spec|
          spec.summary        = #{spec.summary.inspect}
          spec.description    = <<-DESCRIPTION
        #{spec.description.strip}
        DESCRIPTION
          spec.homepage       = #{spec.homepage.inspect}
          spec.author         = #{spec.author.inspect}
          spec.email          = #{spec.email.inspect}
          spec.license        = #{spec.license.inspect}
        end
      EOS
    end

    def __changes__
      changes = []
      @defaults.each_pair do |key,value|
        changes << key unless instance_variable_get("@#{key}") == value
      end
      changes
    end

    private
    def rdoc_options
      [
        "--line-numbers",
        "--main", "README.textile",
        "--title", "#{@gemspec.name} Documentation",
        @source.ruby.to_s, "README.textile"
      ]
    end

    def default(key, value)
      @defaults[key] = value
    end
  end
end
