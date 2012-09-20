require "doubleshot/dependencies/gem_dependency_list"
require "doubleshot/dependencies/jar_dependency_list"

class Doubleshot
  class Dependencies
    
    def initialize
      @gems = GemDependencyList.new
      @jars = JarDependencyList.new  
    end
    
    def gems
      @gems
    end
    
    def jars
      @jars
    end
  end
end