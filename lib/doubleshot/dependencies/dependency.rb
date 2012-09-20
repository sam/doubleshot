class Doubleshot
  class Dependencies
    class Dependency
      attr_accessor :name
      
    	def initialize(name, version = nil)
        @name = name
        @version = version
      end
    end
  end
end