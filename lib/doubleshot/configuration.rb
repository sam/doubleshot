require "doubleshot/dependencies"
require "doubleshot/configuration/source_locations"

class Doubleshot
  class Configuration
    
    def initialize
      @gemspec = Gem::Specification.new
      @gemspec.platform = Gem::Platform.new("java")
      @source = SourceLocations.new
      @target = Pathname("target/**/*")
      @dependencies = Dependencies.new
    end
    
    def source
      @source
    end
    
    def gem(name, *requirements)
      dependency = @dependencies.fetch(name)
      @dependencies.gems.add(dependency)
    end

    def dependencies
      @dependencies
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