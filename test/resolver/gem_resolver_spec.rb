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

    end
  end
end