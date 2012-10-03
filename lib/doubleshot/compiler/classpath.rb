class Doubleshot
  class Compiler
    class Classpath

      def add(path)
        path = Pathname(path.to_s)
        path.realpath
        self
      end
    end
  end
end