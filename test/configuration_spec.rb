#!/usr/bin/env jruby

require_relative "helper.rb"

describe Doubleshot::Configuration do

  before do
    @config = Doubleshot::Configuration.new
  end

  describe "project" do
    it "must accept a project name" do
      @config.project = "doubleshot"
      @config.project.must_equal "doubleshot"
    end

    it "must default the gem name to the project name" do
      @config.project = "doubleshot"
      @config.gemspec.name.must_equal "doubleshot"
    end
  end

  describe "group" do
    it "must allow you to set a group (for JAR packaging)" do
      @config.group = "org.sam.doubleshot"
      @config.group.must_equal "org.sam.doubleshot"
    end

    it "must default to the project name if none is provided" do
      @config.project = "doubleshot"
      @config.group.must_equal "doubleshot"
    end
  end

  describe "version" do
    it "must allow you to set the version" do
      @config.version = "1.0"
      @config.version.must_equal "1.0"
    end

    it "must default the gem version to the project version" do
      @config.version = "1.0"
      @config.gemspec.version.to_s.must_equal "1.0"
    end

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
      @config.gem("listen").must_be_kind_of Doubleshot::Dependencies::GemDependency
    end
  end

  describe "jar" do
    it "must accept a Buildr style JAR dependency string" do
      @config.jar "org.sonatype.aether:aether-api:jar:1.13.1"
      @config.runtime.jars.must_include "org.sonatype.aether:aether-api:jar:1.13.1"
    end

    it "must return a dependency" do
      @config.jar("org.sonatype.aether:aether-api:jar:1.13.1").must_be_kind_of Doubleshot::Dependencies::JarDependency
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

      @config.gemspec.must :validate
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
      @config.project = "Doubleshot"
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

    describe "target" do
      it "must default to target" do
        @config.target.must_equal Pathname("target")
      end

      it "must always return a Pathname" do
        @config.target = "pkg"
        @config.target.must_be_kind_of Pathname
        @config.target.must_equal Pathname("pkg")
      end
    end

    describe "paths" do
      it "must return a readonly collection of paths" do
        @config.paths.must_be_kind_of Doubleshot::ReadonlyCollection
      end

      describe "add_path" do
        it "must return self from add_path" do
          @config.add_path(".gitignore").must_be_same_as @config
        end

        it "must allow you to add arbitrary paths" do
          @config.add_path ".gitignore"
          @config.gemspec.files.must_include(Pathname(".gitignore").to_s)
        end
      end
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

    describe "whitelisting" do

      it "must add whitelisted files" do
        Helper::tmp do |tmp|

          tmp.touch "test.json"
          tmp.touch "test.example"

          @config.source.ruby = "tmp"
          @config.gemspec.files.must_include "tmp/test.json"
          @config.gemspec.files.wont_include "tmp/test.example"

          @config.whitelist ".example"
          @config.gemspec.files.must_include "tmp/test.json"
          @config.gemspec.files.must_include "tmp/test.example"
        end
      end

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
    before do
      @other = Doubleshot::Configuration.new
    end

    it "must equal if attributes are the same" do
      @config.must_be :==, @other
    end
  end

  describe "to_ruby" do
    before do
      @config.project = "doubleshot"
      @config.version = "9000.1"
      @config.gemspec do |spec|
        spec.summary       = "This is my summary."
        spec.description   = <<-DESCRIPTION.margin
        A very detailed description.
        Indeed.
        DESCRIPTION
        spec.author        = "Sam Smoot"
        spec.homepage      = "http://example.com/doubleshot"
        spec.email         = "ssmoot@gmail.com"
        spec.license       = "MIT-LICENSE"
        spec.executables   = [ "doubleshot" ]
      end
    end

    it "must equal generated output" do
      @config.must_equal eval(@config.to_ruby).config
    end

    describe "to_ruby_body" do
      before do
        @output = <<-EOS.margin
          config.project = "doubleshot"
          config.version = "9000.1"

          #{Doubleshot::Configuration::SOURCE_RUBY_MESSAGE}
          #   config.source.ruby    = "lib"

          #{Doubleshot::Configuration::SOURCE_JAVA_MESSAGE}
          #   config.source.java    = "ext/java"

          #{Doubleshot::Configuration::SOURCE_TESTS_MESSAGE}
          #   config.source.tests   = "test"


          #{Doubleshot::Configuration::TARGET_MESSAGE}
          #   config.target = "target"


          #{Doubleshot::Configuration::WHITELIST_MESSAGE}
          #   config.whitelist ".ext"


          #{Doubleshot::Configuration::GEM_DEPENDENCY_MESSAGE}
          #   config.gem "bcrypt-ruby", "~> 3.0"

          #{Doubleshot::Configuration::JAR_DEPENDENCY_MESSAGE}
          #   config.jar "ch.qos.logback:logback:jar:0.5"

          #{Doubleshot::Configuration::DEVELOPMENT_MESSAGE}


          #{Doubleshot::Configuration::GEMSPEC_MESSAGE}
          config.gemspec do |spec|
            spec.summary        = "This is my summary."
            spec.description    = <<-DESCRIPTION
          A very detailed description.
          Indeed.
          DESCRIPTION
            spec.homepage       = "http://example.com/doubleshot"
            spec.author         = "Sam Smoot"
            spec.email          = "ssmoot@gmail.com"
            spec.license        = "MIT-LICENSE"
            spec.executables    = ["doubleshot"]
          end
        EOS
      end

      it "must match the defined format" do
        @config.to_ruby_body.must_equal @output
      end

      describe "non-default attributes" do
        it "must include ruby" do
          @config.source.ruby = "lib/doubleshot"
          @config.to_ruby_body.must_include <<-EOS.margin
          #{Doubleshot::Configuration::SOURCE_RUBY_MESSAGE}
          config.source.ruby    = "lib/doubleshot"
          EOS
        end

        it "must include java" do
          @config.source.java = "ext"
          @config.to_ruby_body.must_include <<-EOS.margin
          #{Doubleshot::Configuration::SOURCE_JAVA_MESSAGE}
          config.source.java    = "ext"
          EOS
        end

        it "must include tests" do
          @config.source.tests = "test/configuration"
          @config.to_ruby_body.must_include <<-EOS.margin
          #{Doubleshot::Configuration::SOURCE_TESTS_MESSAGE}
          config.source.tests   = "test/configuration"
          EOS
        end
      end
    end
  end

  describe "classpath" do
    it "must return a set of paths" do
      skip
      @config.classpath.must_be_kind_of Set
    end

    it "must include all runtime dependencies" do
      skip "until after jar_dependency_spec is implemented"
      @config.jar "foo"
      @config.jar "bar"
      @config.classpath.must_include Pathname("foo")
      @config.classpath.must_include Pathname("bar")
    end

    it "must include all development dependencies" do
      skip "until after jar_dependency_spec is implemented"

      @config.development do
        @config.jar "foo"
        @config.jar "bar"
      end

      @config.classpath.must_include Pathname("foo")
      @config.classpath.must_include Pathname("bar")
    end
  end

end
