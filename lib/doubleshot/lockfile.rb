class Doubleshot
  class Lockfile

    class UnlockedDependencyError < StandardError
      def initialize(dependency)
        super "Dependency #{dependency.to_s.inspect} is unlocked!"
      end
    end

    class UnknownDependencyTypeError < NotImplementedError
      def initialize(dependency)
        super "Handling for this dependency is not implemented: #{dependency.inspect}"
      end
    end

    attr_reader :path

    def initialize(path = "Doubleshot.lock")
      @path = Pathname(path.to_s)
      @gems = Dependencies::GemDependencyList.new
      @jars = Dependencies::JarDependencyList.new
    end

    def exist?
      @path.exist?
    end

    def mtime
      @path.mtime
    end

    def gems
      load
      ReadonlyCollection.new @gems
    end

    def jars
      load
      ReadonlyCollection.new @jars
    end

    def empty?
      @gems.empty? && @jars.empty?
    end

    def add(dependency)
      if dependency.class == Dependencies::Dependency
        raise ArgumentError.new("+dependency+ must be a concrete type (JarDependency or GemDependency).")
      elsif dependency.class < Dependencies::Dependency
        if dependency.locked?
          case dependency
            when Dependencies::JarDependency then @jars.add(dependency)
            when Dependencies::GemDependency then @gems.add(dependency)
            else raise UnknownDependencyTypeError.new(dependency)
          end
        else
          raise UnlockedDependencyError.new(dependency)
        end
      else
        raise ArgumentError.new("+dependency+ must be a type of Doubleshot::Dependencies::Dependency.")
      end

      self
    end

    def load
      unless @loaded
        (data["JARS"] || []).each do |buildr_string|
          @jars.add Dependencies::JarDependency.new(buildr_string)
        end

        # TODO: add gems to this method
        # (data["GEMS"] || []).each do |gem_string|
        #   @gems.add Dependencies::GemDependency.new(gem_string)
        # end
      end

      @loaded = true
    end

    private

    def data
      @data ||= (@path.exist? ? YAML.load(@path.read) : {})
    end

  end # class Lockfile
end # class Doubleshot
