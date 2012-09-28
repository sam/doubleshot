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

    def initialize
      @defaults                    = {}
      @gemspec                     = Gem::Specification.new
      @gemspec.platform            = Gem::Platform.new("java")
      @source                      = SourceLocations.new
      @target                      = default :target, Pathname("target")

      @runtime_dependencies        = Dependencies.new
      @development_dependencies    = Dependencies.new
      @development_environment     = false

      @paths                       = default :paths, DEFAULT_PATHS.dup
      @whitelist                   = default :whitelist, DEFAULT_WHITELIST.dup
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
        @gemspec.require_paths = [ @source.ruby.to_s ]

        test_files = []
        @source.tests.find do |path|
          test_files << path.to_s if path.file?
        end
        @gemspec.test_files = test_files

        files = []

        @paths.each do |path|
          Pathname::glob(path).each do |match|
            files << match.to_s if match.file?
          end
        end

        @source.ruby.find do |path|
          files << path.to_s if path.file? && @whitelist.include?(path.extname)
        end

        @source.java.find do |path|
          files << path.to_s if path.file? && @whitelist.include?(path.extname)
        end

        if @target.exist?
          @target.find do |path|
            files << path.to_s if path.file?  
          end
        end

        @gemspec.files.concat(files)

        @runtime_dependencies.gems.each do |dependency|
          @gemspec.add_runtime_dependency dependency.name, *dependency.requirements
        end

        @development_dependencies.gems.each do |dependency|
          @gemspec.add_development_dependency dependency.name, *dependency.requirements
        end

        @gemspec.add_development_dependency "doubleshot"

        @gemspec
      end
    end

    def to_ruby
      <<-EOS.margin
        # encoding: UTF-8

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
          spec.name           = #{spec.name.inspect}
          spec.version        = #{spec.version.to_s.inspect}
          spec.summary        = #{spec.summary.inspect}
          spec.description    = <<-DESCRIPTION
        #{spec.description.strip}
        DESCRIPTION
          spec.homepage       = #{spec.homepage.inspect}
          spec.author         = #{spec.author.inspect}
          spec.email          = #{spec.email.inspect}
          spec.license        = #{spec.license.inspect}
          spec.executables    = #{spec.executables.inspect}
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
