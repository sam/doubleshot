require "doubleshot/dependencies/dependency_list"
require "doubleshot/dependencies/gem_dependency"

class Doubleshot
  class Dependencies
    class GemDependencyList < DependencyList
      DEPENDENCY_CLASS = GemDependency
    end
  end
end