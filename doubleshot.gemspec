# -*- encoding: utf-8 -*-

Gem::Specification.new do |spec|
  spec.name = "doubleshot"
  spec.summary = "Doubleshot is a build and dependency tool for mixed Java and Ruby projects"
  spec.description = <<-EOS
Doubleshot will download dependencies on demand, compile your Java sources and
let you spend most of your time in Ruby without having to juggle two different
dependency management tools, different build tools and being forced to execute
your code through Rake or Maven based tools.
EOS
  spec.author = "Sam Smoot"
  spec.homepage = "https://github.com/sam/doubleshot"
  spec.email = "ssmoot@gmail.com"
  spec.version = "0.1.0"
  spec.platform = Gem::Platform::RUBY
  spec.files         = `git ls-files`.split("\n") + Dir["target/**/*.class"]
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.require_paths = ["lib"]

  spec.rdoc_options = [
    "-T", "doubleshot",
    "--line-numbers",
    "--main", "README.textile",
    "--title", "Doubleshot Documentation",
    "lib", "README.textile"
  ]
  
  # Build dependencies:
  spec.add_dependency "bundler"
  spec.add_dependency "jbundler"
  spec.add_development_dependency "rdoc", ">= 2.4.2"
  
  # Test dependencies:
  # spec.add_development_dependency "minitest", ">= 3.0.1"
  # spec.add_development_dependency "minitest-wscolor"
  # spec.add_development_dependency "listen"
  # spec.add_development_dependency "simplecov"
end