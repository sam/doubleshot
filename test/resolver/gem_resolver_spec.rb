#!/usr/bin/env jruby

# encoding: utf-8

require_relative "../helper"

describe Doubleshot::Resolver::GemResolver do
  before do
    @resolver = Doubleshot::Resolver::GemResolver.new "stub://example.org"
  end

  describe "fetch" do
    before do
      @dependencies = Doubleshot::Dependencies::GemDependencyList.new
    end

    it "must return the same GemDependencyList" do
      @dependencies.fetch("rdoc")
      @resolver.resolve!(@dependencies).must_be_same_as @dependencies
    end

    it "must take a GemDependencyList and populate nested dependencies" do
      @dependencies.fetch("rdoc")
      @resolver.resolve! @dependencies
      @dependencies.size.must_equal 2
    end

    it "must raise a MissingGemError if a dependency can't be resolved" do
      rdoc = @dependencies.fetch("rdoc")
      rdoc.add_requirement "> 9000" # IT'S OVER 9000!!! (this version doesn't exist)
      -> { @resolver.resolve! @dependencies }.must_raise(Doubleshot::Resolver::GemResolver::MissingGemError)
    end

    it "must only add dependencies that meet requirements" do
      rdoc = @dependencies.fetch("rdoc")
      rdoc.add_requirement "~> 3.9.0"
      @resolver.resolve! @dependencies
      # This previous version of the rdoc gem doesn't have the json dependency:
      @dependencies.size.must_equal 1
    end

    describe "scenarios" do
      # list of scenarios we expect to be resolvable
      describe "success" do
        it "should succeed on independent gems" do
          skip
          @dependencies.add Doubleshot::Dependencies::GemDependency.new "minitest"
          @dependencies.add Doubleshot::Dependencies::GemDependency.new "rack"
          json_dependency = Doubleshot::Dependencies::GemDependency.new "json"
          json_dependency.add_requirement "= 1.7.4"
          @dependencies.add json_dependency
          @resolver.resolve! @dependencies
          @dependencies.size.must_equal 3
        end

        it "should succeed on simple linear dependencies" do
          skip
          rdoc_dependency = Doubleshot::Dependencies::GemDependency.new "rdoc"
          rdoc_dependency.add_requirement "=3.8.3"
          @dependencies.add rdoc_dependency
          @resolver.resolve! @dependencies
          @dependencies.size.must_equal 3
        end

        it "should find the latest possible dependencies" do
          skip
          @dependencies.add Doubleshot::Dependencies::GemDependency.new "top-level"
          @resolver.resolve! @dependencies
          @dependencies.size.must_equal 3
          @dependencies.fetch("top-level").version.must_equal "1.0"
          @dependencies.fetch("mid-level-1").version.must_equal "2.0"
          @dependencies.fetch("mid-level-2").version.must_equal "2.0"
          @dependencies.fetch("bottom-level").version.must_equal "2.3"
        end

        it "should correctly resolve dependencies when one resolution exists but it is not the latest" do
          skip
          @dependencies.add Doubleshot::Dependencies::GemDependency.new "get-the-old-one"
          @resolver.resolve! @dependencies
          @dependencies.size.must_equal 3
          @dependencies.fetch("get-the-old-one").version.must_equal "1.0"
          @dependencies.fetch("locked-mid-1").version.must_equal "1.3"
          @dependencies.fetch("locked-mid-2").version.must_equal "1.4"
          @dependencies.fetch("old-bottom").version.must_equal "0.5"
        end
      end

      # list of scenarios we expect to be unresolvable
      describe "failure" do
        it "should fail on conflicting dependencies" do
          skip
          locked_mid_1_dependency = Doubleshot::Dependencies::GemDependency.new "locked-mid-1"
          locked_mid_1_dependency.add_requirement "2.0"

          locked_mid_2_dependency = Doubleshot::Dependencies::GemDependency.new "locked-mid-2"
          locked_mid_2_dependency.add_requirement "2.0"

          @dependencies.add locked_mid_1_dependency
          @dependencies.add locked_mid_2_dependency
          -> { @resolver.resolve! @dependencies }.must_raise(Doubleshot::Resolver::GemResolver::UnresolvableDependenciesError)
        end

        it "should fail when no possible version dependency exists in the source(s)" do
          skip
          @dependencies.fetch "oops"
          -> { @resolver.resolve! @dependencies }.must_raise(Doubleshot::Resolver::GemResolver::MissingGemError)
        end
      end
    end
  end
end
