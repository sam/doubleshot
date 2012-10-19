require "uri"

class Doubleshot
  class Resolver
    def initialize(*repositories)
      @repositories = repositories.map do |repository|
        URI.parse repository.to_s
      end
      raise ArgumentError.new("no repositories specified") if @repositories.empty?
    end

    def fetch(dependencies)
      raise NotImplementedError.new
    end

    def repositories
      ReadonlyCollection.new(@repositories)
    end
  end
end

require "doubleshot/resolver/gem_resolver"
require "doubleshot/resolver/jar_resolver"