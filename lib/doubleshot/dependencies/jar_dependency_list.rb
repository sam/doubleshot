require "doubleshot/dependencies/dependency_list"
require "doubleshot/dependencies/jar_dependency"

class Doubleshot
  class Dependencies
    class JarDependencyList < DependencyList
      DEPENDENCY_CLASS = JarDependency
    end
  end
end