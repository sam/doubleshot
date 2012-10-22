require "uri"

class Doubleshot
  class Resolver
    class GemResolver

      class Source

        def self.map(*mime_types)
          mime_types.each do |mime_type|
            mappings[mime_type.to_s] = self
          end
        end

        def self.mappings
          @@mappings ||= {}
        end

        def self.new(uri)
          uri = URI.parse(uri.to_s)
          instance = mappings[uri.scheme].allocate
          instance.send(:initialize, uri)
          instance
        end

        def initialize(uri)
          @uri = uri
        end

        SUPPORTED_PLATFORMS = [ /\bjava\b/i, /^jruby$/i, /^ruby$/i ]
      end
    end
  end
end

require "doubleshot/resolver/gem_resolver/gem_source"