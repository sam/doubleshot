class Doubleshot

  class ReadonlyCollection
    include Enumerable

    def initialize(collection)
      unless collection.is_a? Enumerable
        raise ArgumentError.new("+collection+ must be an Enumerable")
      end
      @collection = collection
    end

    def each
      @collection.each { |entry| yield entry }
    end

    def size
      entries.size
    end
    alias :length :size

    def empty?
      entries.empty?
    end
    
    def eql?(other)
      other.is_a?(self.class) && entries == other.entries
    end
    alias :== :eql?
  end

end