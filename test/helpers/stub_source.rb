module Helper
  class StubSource < Doubleshot::Resolver::GemResolver::Source
    map :stub

    def self.index(gems)
      @@index = {}
      gems.each_pair do |name, versions|
        specs = @@index[name] ||= {}
        versions.each_pair do |version, dependencies|
          spec = specs[Gem::Version.new(version)] = Gem::Specification.new
          spec.name = name
          spec.version = version
          dependencies.each_pair do |name, versions|
            spec.add_runtime_dependency name, *versions
          end
        end
      end
    end

    def versions(name)
      @@index[name.to_s].keys
    end

    def spec(name, version)
      @@index[name.to_s][version]
    end

    index(
      "rdoc" => {
        "3.12" => { "json" => "~>1.4" },
        "3.9.0" => {},
        "3.8.3" => { "json" => "=1.7.2" }
      },
      "json" => {
        "1.7.5" => { "erubis" => "~>2.6.6" },
        "1.7.4" => {},
        "1.7.3" => {},
        "1.7.2" => { "erubis" => "2.6.5" }
      },
      "minitest-wscolor" => {
        "0.0.3" => { "minitest" => ">=2.3.1" },
        "0.0.2" => {}
      },
      "minitest" => {
        "3.0.4" => {},
        "3.0.3" => {},
        "3.0.0" => {},
        "2.3.1" => {},
        "2.3.0" => {},
      },
      "erubis" => {
        "2.7.0" => { "minitest" => ">=3.0.0" },
        "2.6.6" => {},
        "2.6.5" => {}
      },
      "rack" => {
        "1.4.1" => {},
        "1.4.0" => {},
        "1.3.6" => {},
        "1.2.5" => {},
        "1.1.3" => {}
      },
      "harbor" => {
        "0.16.12" => { "erubis" => ">=0", "rack" => "~>1.0.0", "json" => ">=0" },
        "0.16.11" => { "erubis" => ">=0", "rack" => "~>1.0.0" },
        "0.16.10" => { "erubis" => ">=0", "rack" => ">=0" }
      },
      "hello" => {
        "4.0" => { "harbor" => "~>0.16.10", "json" => "~>1.7.0", "minitest-wscolor" => "=0.0.3" },
        "3.9" => { "harbor" => ">=0", "json" => ">=0", "minitest-wscolor" => ">=0", "minitest" => "~>2.3" },
        "3.8" => { "harbor" => ">=0", "erubis" => "~>2.6.5" },
        "2.2" => { "harbor" => ">=0" }
      },
      "top-level" => {
        "1.0" => { "mid-level-1" => ">=0", "mid-level-2" => ">=0" }
      },
      "mid-level-1" => {
        "2.0" => { "bottom-level" => [ ">=1.0", "<=3.0" ] },
        "1.0" => {}
      },
      "mid-level-2" => {
        "2.0" => { "bottom-level" => ">=2.0" },
        "1.0" => {}
      },
      "bottom-level" => {
        "2.3" => {},
        "2.0" => {},
        "1.3" => {},
        "1.0" => {},
        "0.9" => {}
      },
      "get-the-old-one" => {
        "1.0" => { "locked-mid-1" => ">=0", "locked-mid-2" => ">=0" },
        "0.5" => {}
      },
      "locked-mid-1" => {
        "2.0" => { "old-bottom" => "=2.0" },
        "1.3" => { "old-bottom" => "=0.5" },
        "1.0" => {}
      },
      "locked-mid-2" => {
        "2.0" => { "old-bottom" => "=2.1" },
        "1.4" => { "old-bottom" => "=0.5" },
        "1.0" => {}
      },
      "old-bottom" => {
        "2.1" => {},
        "2.0" => {},
        "1.0" => {},
        "0.5" => {}
      },
      "oops" => {
        "1.0" => { "oops-2" => "=2.0" }
      },
      "oops-2" => {
        "1.0" => {}
      }
    )
  end
end
