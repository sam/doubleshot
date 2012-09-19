class Doubleshot
  class Configuration
    
    def initialize
      @gemspec = Gem::Specification.new
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