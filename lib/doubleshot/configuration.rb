require "doubleshot/dependencies"
require "doubleshot/configuration/source_locations"

class Doubleshot
  class Configuration

    def initialize
      @gemspec                     = Gem::Specification.new
      @gemspec.platform            = Gem::Platform.new("java")
      @source                      = SourceLocations.new
      @target                      = Pathname("target/**/*")

      @runtime_dependencies        = Dependencies.new
      @development_dependencies    = Dependencies.new
      @development_environment = false
    end

    def source
      @source
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

        [ "Doubleshot", "*LICENSE*", "README*" ].each do |path|
          Pathname::glob(path).each do |match|
            files << match.to_s if match.file?
          end
        end

        @source.ruby.find do |path|
          files << path.to_s if path.file?
        end

        @source.java.find do |path|
          files << path.to_s if path.file?
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

        @gemspec
      end
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
  end
end
