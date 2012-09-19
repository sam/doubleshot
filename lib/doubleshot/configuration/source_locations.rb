class Doubleshot
  class Configuration
    class SourceLocations
      
      def initialize
        @ruby = Pathname("lib")
        @java = Pathname("ext/java")
      end
      
      def ruby
        @ruby
      end

      def ruby=(path)
        check = Pathname(path.to_s)
        
        unless check.directory?
          raise IOError.new("+path+ must be a directory but was #{path.inspect}")
        end
        
        @ruby = check
      end

      def java
        @java
      end
      
      def java=(path)
        check = Pathname(path.to_s)
         
         unless check.directory?
           raise IOError.new("+path+ must be a directory but was #{path.inspect}")
         end
         
         @java = check   
      end
      
    end
  end
end 