#!/usr/bin/env jruby

# encoding: utf-8

require_relative "../../helper"

describe Doubleshot::Resolver::GemResolver::Dependency do
  before do
    @dependency = Doubleshot::Resolver::GemResolver::Dependency.new(
            Doubleshot::Resolver::GemResolver::Artifact.new(nil, "something_using_ntp", "1.0"),
            "ntp")
  end

  describe "ClassMethods" do
    describe "::new" do
      describe "when no value for 'constraint' is given" do
        it "uses a default of >= 0" do
          @dependency.constraint.to_s.must_equal ">= 0"
        end
      end
    end
  end

  describe "#eql?" do
    it "returns true if the other object is an instance of Solve::Dependency with the same constraint and artifact" do
      other = Doubleshot::Resolver::GemResolver::Dependency.new(
                Doubleshot::Resolver::GemResolver::Artifact.new(nil, "something_using_ntp", "1.0"),
                "ntp")

      @dependency.must_equal other
    end
  end
end