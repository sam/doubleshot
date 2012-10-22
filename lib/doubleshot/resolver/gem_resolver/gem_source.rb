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
                  Marshal.load(Gem.inflate(open("#{@uri}/quick/Marshal.4.8/#{name}-#{version}.gemspec.rz").read))
                rescue
                  nil
                end
              end
            end
          end
        end

        def __versions__
          @versions ||= begin
            versions = Hash.new { |h,k| h[k] = [] }

            Marshal::load(Zlib::GzipReader.new(open("#{@uri}/specs.4.8.gz")).read).each do |entry|
              if SUPPORTED_PLATFORMS.any? { |platform| entry.last =~ platform }
                versions[entry[0]] << entry[1].to_s
              end
            end

            versions
          end
        end
      end
    end
  end
end