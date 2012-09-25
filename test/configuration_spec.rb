#!/usr/bin/env jruby

require_relative "helper.rb"

describe Doubleshot::Configuration do

  before do
    @config = Doubleshot::Configuration.new
  end

  describe "gem" do
    it "must accept a gem name" do
      @config.gem "listen"
      @config.runtime.gems.must_include "listen"
    end

    it "must accept a list of requirements" do
      @config.gem "listen", ">0.4.0"
    end
    
    it "must return a dependency" do
      @config.gem("listen").must_be_kind_of Doubleshot::Dependencies::Dependency
    end
  end

  describe "gemspec" do
    it "must be a Gem::Specification" do
      @config.gemspec.must_be_kind_of Gem::Specification
    end

    it "must accept a block" do
      @config.method(:gemspec).parameters.detect do |parameter|
        parameter.first == :block
      end.wont_be_nil
    end

    it "must allow a sample gemspec" do
      begin
        @config.gemspec do |spec|
          spec.name          = "Doubleshot"
          spec.summary       = "Build, Dependencies and Testing all in one!"
          spec.description   = "Description"
          spec.author        = "Sam Smoot"
          spec.homepage      = "https://github.com/sam/doubleshot"
          spec.email         = "ssmoot@gmail.com"
          spec.version       = "1.0"
          spec.license       = "MIT-LICENSE"
          spec.executables   = [ "doubleshot" ]
        end
      rescue Exception => e
        fail e
      end

      @config.gemspec.validate.must_equal true
    end

    it "must add dependencies to the gemspec" do
      @config.gem "listen"
      @config.gemspec.runtime_dependencies.first.name.must_equal "listen"
    end

    it "must add requirements to dependencies" do
      @config.gem "listen", "~> 0.1.0"
      @config.gemspec.runtime_dependencies.first.requirements_list.must_include "~> 0.1.0"
    end

    it "must default the Platform to JRuby" do
      @config.gemspec.platform.os.must_equal "java"
    end

    it "must provide sane defaults for rdoc" do
      @config.gemspec.name = "Doubleshot"
      @config.gemspec.rdoc_options.must_equal([
                                              "--line-numbers",
                                              "--main", "README.textile",
                                              "--title", "Doubleshot Documentation",
                                              "lib", "README.textile" ])
    end

    it "require_paths must default to the ruby source location" do
      @config.gemspec.require_paths.must_equal [ "lib" ]
    end

    it "require_paths must be updated when ruby source location is modified" do
      @config.source.ruby = "test"
      @config.gemspec.require_paths.must_equal [ "test" ]
    end

    it "should include test_files if present" do
      @config.gemspec.test_files.sort.must_equal Dir["test/**/*"].select { |path| Pathname(path).file? }.sort
    end

    it "must allow you to add arbitrary paths" do
      @config.add_path ".gitignore"
      @config.gemspec.files.must_include(Pathname(".gitignore").to_s)
    end

    it "files must contain Ruby sources, Java sources, Doubleshot, LICENSE, README and any build files" do
      @config.gemspec.files.sort.must_equal(
        Dir[
          "lib/**/*.rb",
          "ext/java/**/*.java",
          "Doubleshot",
          "*LICENSE*",
          "README*",
          "target/**/*",
          "test/**/*"
      ].select { |path| Pathname(path).file? }.sort
      )
    end

    describe "development" do
      before do
        @config.development do
          @config.gem "minitest", ">= 3.0.1"
        end
      end

      it "must add dependencies to the development list" do
        @config.development.gems.must_include "minitest"
      end

      it "won't add dependencies to the main list" do
        @config.runtime.gems.wont_include "minitest"
      end

      describe "gemspec" do
        it "must add dependencies to the gemspec" do
          @config.gemspec.development_dependencies.first.name.must_equal "minitest"
        end

        it "must add requirements to dependencies" do
          @config.gemspec.development_dependencies.first.requirements_list.must_include ">= 3.0.1"
        end
      end
    end
  end

  describe "equality" do
    it "must override the equality operator to consider requirements" do
      skip
      @config.must_be :==, @other
    end
  end

  describe "to_ruby" do
    it "must equal generated output" do
      skip
      @config.must_equal eval(@config.to_ruby)
    end
  end

end