require "open-uri"
require "zlib"

class Doubleshot
  class Resolver
    class GemResolver
      class GemSource < Source

        map :http, :https

        SUPPORTED_PLATFORMS = [ /\bjava\b/i, /^jruby$/i, /^ruby$/i ]

        def versions(name)
          __versions__[name]
        end

        def spec(name, version)
          __specs__[name][version]
        end

        private
        def __specs__
          @specs ||= begin
            Hash.new do |h,name|
              h[name] = Hash.new do |h2,version|
                begin
                  puts "Loading Gem::Specification for #{name}:#{version}..."
                  Marshal.load(Gem.inflate(open(
                    "#{@uri.to_s.ensure_ends_with("/")}quick/Marshal.4.8/#{name}-#{version}.gemspec.rz"
                    ).read))
                rescue
                  puts "Gem::Specification for #{name}:#{version} not found!"
                  nil
                end
              end
            end
          end
        end

        def __versions__
          @versions ||= Hash.new do |h,k|
            versions = h[k] = []
            dep = Gem::Dependency.new(k, Gem::Requirement::default)
            puts "Fetching list of versions for #{k.inspect}"
            Gem::SpecFetcher::fetcher.find_matching(dep, true, false, false).map do |entry|
              if tuple = entry.first
                if SUPPORTED_PLATFORMS.any? { |platform| tuple.last =~ platform }
                  versions << tuple[1]
                end # if SUPPORTED_PLATFORMS
              end # if tuple = entry.first
            end # Gem::SpecFetcher::fetcher.find_matching
            versions
          end # Hash.new
        end # __versions__
      end
    end
  end
end