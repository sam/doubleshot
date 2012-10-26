#!/usr/bin/env jruby

# encoding: utf-8

require_relative "../../helper"

describe Doubleshot::Resolver::GemResolver::Artifact do

  before do
    @graph = Doubleshot::Resolver::GemResolver::Graph.new
    @artifact = Doubleshot::Resolver::GemResolver::Artifact.new(@graph, "listen", "1.0")
  end

  describe "equality" do
    it "must equal another artifact with the same name and version" do
      artifact_1 = Doubleshot::Resolver::GemResolver::Artifact.new(@graph, "listen", "1.0")
      artifact_2 = Doubleshot::Resolver::GemResolver::Artifact.new(@graph, "listen", "1.0")
      artifact_1.must_equal artifact_2
    end

    it "must not equal another artifact with the same name but different version" do
      artifact_1 = Doubleshot::Resolver::GemResolver::Artifact.new(@graph, "listen", "1.0")
      artifact_2 = Doubleshot::Resolver::GemResolver::Artifact.new(@graph, "listen", "2.0")
      artifact_1.wont_equal artifact_2
    end

    it "must not equal another artifact with the same version but different name" do
      artifact_1 = Doubleshot::Resolver::GemResolver::Artifact.new(@graph, "listen", "1.0")
      artifact_2 = Doubleshot::Resolver::GemResolver::Artifact.new(@graph, "not_listen", "1.0")
      artifact_1.wont_equal artifact_2
    end
  end

  describe "sorting" do
    it "must sort artifacts by their name, then version number" do
      artifact_1 = Doubleshot::Resolver::GemResolver::Artifact.new(@graph, "listen", "1.0")
      artifact_2 = Doubleshot::Resolver::GemResolver::Artifact.new(@graph, "listen", "2.0")

      [artifact_2, artifact_1].sort.must_equal [artifact_1, artifact_2]
    end
  end

  describe "#dependencies" do
    it "returns an array" do
      @artifact.dependencies.must_be_kind_of Array
    end

    it "returns an empty array if no dependencies have been accessed" do
      @artifact.dependencies.must_be_empty
    end
  end

  describe "#depends" do
    before do
      @name = "nginx"
      @constraint = "~> 0.101.5"
    end

    describe "given a name and constraint argument" do
      describe "given the dependency of the given name and constraint does not exist" do
        it "returns a Solve::Artifact" do
          @artifact.depends(@name, @constraint).must_be_kind_of Doubleshot::Resolver::GemResolver::Artifact
        end

        it "adds a dependency with the given name and constraint to the list of dependencies" do
          @artifact.depends(@name, @constraint)

          @artifact.dependencies.size.must_equal 1
          @artifact.dependencies.first.name.must_equal @name
          @artifact.dependencies.first.constraint.to_s.must_equal @constraint
        end
      end
    end

    describe "given only a name argument" do
      it "adds a dependency with a all constraint (>= 0.0.0)" do
        @artifact.depends(@name)

        @artifact.dependencies.size.must_equal 1
        @artifact.dependencies.first.constraint.to_s.must_equal ">= 0"
      end
    end
  end

  describe "::get_dependency" do

    it "returns an instance of Solve::Dependency matching the given name and constraint" do
      @artifact.depends("nginx", "~> 1.2.3")
      dependency = @artifact.get_dependency("nginx", "~> 1.2.3")

      dependency.must_be_kind_of Doubleshot::Resolver::GemResolver::Dependency
      dependency.name.must_equal "nginx"
      dependency.constraint.to_s.must_equal "~> 1.2.3"
    end
  end

  describe "#delete" do

    describe "given the artifact is not the member of a graph" do
      it "returns nil" do
        artifact = Doubleshot::Resolver::GemResolver::Artifact.new(nil, "listen", "1.0")
        artifact.delete.must_be_nil
      end
    end
  end
end