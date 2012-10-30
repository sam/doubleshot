#!/usr/bin/env jruby

# encoding: utf-8

require_relative "../../helper"

describe Doubleshot::Resolver::GemResolver::Graph do
  before do
    @graph = Doubleshot::Resolver::GemResolver::Graph.new
  end

  describe "ClassMethods" do
    describe "::artifact_key" do
      it "returns a symbol containing the name and version of the artifact" do
        Doubleshot::Resolver::GemResolver::Graph::artifact_key("nginx", "1.2.3").must_equal :'nginx-1.2.3'
      end
    end

    describe "::dependency_key" do
      it "returns a symbol containing the name and constraint of the dependency" do
        Doubleshot::Resolver::GemResolver::Graph::dependency_key("ntp", "= 2.3.4").must_equal :'ntp-= 2.3.4'
      end
    end
  end

  describe "#artifacts" do
    describe "given a name and version argument" do
      before do
        @name = "nginx"
        @version = "0.101.5"
      end

      describe "given the artifact of the given name and version does not exist" do
        it "returns a Doubleshot::Resolver::GemResolver::Artifact" do
          @graph.artifacts(@name, @version).must_be_kind_of Doubleshot::Resolver::GemResolver::Artifact
        end

        it "the artifact has the given name" do
          @graph.artifacts(@name, @version).name.must_equal @name
        end

        it "the artifact has the given version" do
          @graph.artifacts(@name, @version).version.to_s.must_equal @version
        end

        it "adds an artifact to the artifacts collection" do
          @graph.artifacts(@name, @version)

          @graph.artifacts.size.must_equal 1
        end

        it "the artifact added matches the given name" do
          @graph.artifacts(@name, @version)

          @graph.artifacts[0].name.must_equal @name
        end

        it "the artifact added matches the given version" do
          @graph.artifacts(@name, @version)

          @graph.artifacts[0].version.to_s.must_equal @version
        end
      end
    end

    describe "given no arguments" do
      it "returns an array" do
        @graph.artifacts.must_be_kind_of Array
      end

      it "returns an empty array if no artifacts have been accessed" do
        @graph.artifacts.size.must_equal 0
      end

      it "returns an array containing an artifact if one was accessed" do
        @graph.artifacts("nginx", "0.101.5")

        @graph.artifacts.size.must_equal 1
      end
    end

    describe "given an unexpected number of arguments" do
      it "raises an ArgumentError if more than two are provided" do
        -> { @graph.artifacts(1, 2, 3) }.must_raise ArgumentError, "Unexpected number of arguments. You gave: 3. Expected: 0 or 2."
      end

      it "raises an ArgumentError if one argument is provided" do
        -> { @graph.artifacts(nil) }.must_raise ArgumentError, "Unexpected number of arguments. You gave: 1. Expected: 0 or 2."
      end

      it "raises an ArgumentError if one of the arguments provided is nil" do
        -> { @graph.artifacts("nginx", nil) }.must_raise ArgumentError, 'A name and version must be specified. You gave: ["nginx", nil].'
      end
    end
  end

  describe "#get_artifact" do
    before do
      @graph.artifacts("nginx", "1.0.0")
    end

    it "returns an instance of artifact of the matching name and version" do
      artifact = @graph.get_artifact("nginx", "1.0.0")

      artifact.must_be_kind_of Doubleshot::Resolver::GemResolver::Artifact
      artifact.name.must_equal "nginx"
      artifact.version.to_s.must_equal "1.0.0"
    end

    describe "when an artifact of the given name is not in the collection of artifacts" do
      it "returns nil" do
        @graph.get_artifact("nothere", "1.0.0").must_be_nil
      end
    end
  end

  describe "#versions" do
    before do
      @graph.artifacts("nginx", "1.0.0")
      @graph.artifacts("nginx", "2.0.0")
      @graph.artifacts("nginx", "3.0.0")
      @graph.artifacts("nginx", "4.0.0")
      @graph.artifacts("nginx", "5.0.0")
      @graph.artifacts("nginx", "4.0.0")
    end

    it "returns all the artifacts matching the given name" do
      @graph.versions("nginx").size.must_equal 5
    end

    describe "given an optional constraint value" do
      it "returns only the artifacts matching the given constraint value and name" do
        @graph.versions("nginx", ">= 4.0.0").size.must_equal 2
      end
    end
  end

  describe "#add_artifact" do
    before do
      @artifact = Doubleshot::Resolver::GemResolver::Artifact.new(@graph, "nginx", "1.0.0")
    end

    it "adds a Doubleshot::Resolver::GemResolver::Artifact to the collection of artifacts" do
      @graph.add_artifact @artifact

      @graph.artifacts.must_include @artifact
      @graph.artifacts.size.must_equal 1
    end

    it "should not add the same artifact twice to the collection" do
      @graph.add_artifact @artifact
      @graph.add_artifact @artifact

      @graph.artifacts.size.must_equal 1
    end
  end

  describe "#remove_artifact" do
    before do
      @artifact = Doubleshot::Resolver::GemResolver::Artifact.new(@graph, "nginx", "1.0.0")
    end

    describe "given the artifact is a member of the collection" do
      before do
        @graph.add_artifact @artifact
      end

      it "removes the Solve::Artifact from the collection of artifacts" do
        @graph.remove_artifact(@artifact)

        @graph.artifacts.size.must_equal 0
      end

      it "returns the removed Solve::Artifact" do
        @graph.remove_artifact(@artifact).must_equal @artifact
      end
    end

    describe "given the artifact is not a member of the collection" do
      it "should return nil" do
        @graph.remove_artifact(@artifact).must_be_nil
      end
    end
  end

  describe "#has_artifact?" do
    before do
      @artifact = Doubleshot::Resolver::GemResolver::Artifact.new(@graph, "nginx", "1.0.0")
    end

    it "returns true if the given Solve::Artifact is a member of the collection" do
      @graph.add_artifact @artifact

      @graph.has_artifact?(@artifact.name, @artifact.version).must_equal true
    end

    it "returns false if the given Solve::Artifact is not a member of the collection" do
      @graph.has_artifact?(@artifact.name, @artifact.version).must_equal false
    end
  end

  describe "eql?" do
    before do
      @graph = Doubleshot::Resolver::GemResolver::Graph.new
      @graph.artifacts("A", "1.0.0").depends("B", "1.0.0")
      @graph.artifacts("A", "2.0.0").depends("C", "1.0.0")
      @graph
    end

    it "returns false if other isn't a Solve::Graph" do
      @graph.wont_equal "chicken"
    end

    it "returns true if other is a Solve::Graph with the same artifacts and dependencies" do
      other = Doubleshot::Resolver::GemResolver::Graph.new
      other.artifacts("A", "1.0.0").depends("B", "1.0.0")
      other.artifacts("A", "2.0.0").depends("C", "1.0.0")

      @graph.must_equal other
    end

    it "returns false if the other is a Solve::Graph with the same artifacts but different dependencies" do
      other = Doubleshot::Resolver::GemResolver::Graph.new
      other.artifacts("A", "1.0.0")
      other.artifacts("A", "2.0.0")

      @graph.wont_equal other
    end

    it "returns false if the other is a Solve::Graph with the same dependencies but different artifacts" do
      other = Doubleshot::Resolver::GemResolver::Graph.new
      other.artifacts("A", "1.0.0").depends("B", "1.0.0")
      other.artifacts("A", "2.0.0").depends("C", "1.0.0")
      other.artifacts("B", "1.0.0")

      @graph.wont_equal other
    end
  end
end