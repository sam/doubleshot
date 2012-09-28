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

    def empty?
      @gems.empty? && @jars.empty?
    end

    def eql?(other)
      other.is_a?(self.class) &&
        other.gems == gems &&
        other.jars == jars
    end
    alias :== :eql?
  end
end
