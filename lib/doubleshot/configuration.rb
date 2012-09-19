require "doubleshot/configuration/source_locations"

class Doubleshot
  class Configuration
    
    def initialize
      @gemspec = Gem::Specification.new
      @gemspec.platform = Gem::Platform.new("java")
      @source = SourceLocations.new
    end
    
    def source
      @source
    end
    
    def gemspec(&b)
      if b
        yield @gemspec
      else
        @gemspec
      end
    end
  end
end