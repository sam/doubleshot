#!/usr/bin/env ruby

require_relative "../helper"

describe Doubleshot::Dependencies::GemDependency do

  before do
    @dependency = Doubleshot::Dependencies::GemDependency.new "listen"
    @other      = Doubleshot::Dependencies::GemDependency.new "listen"
  end

  describe "add_requirement" do
    it "must return a Gem::Requirement object" do
      @dependency.add_requirement("1.0").must_be_kind_of Gem::Requirement
    end

    it "must not duplicate requirements" do
      @dependency.add_requirement("2.0")
      @dependency.add_requirement("2.0")
      @dependency.requirements.size.must_equal 1
    end
  end

  describe "equality" do
    it "must override the equality operator to consider requirements" do
      @dependency.must_be :==, @other
      @other.add_requirement ">= 0.1.0"
      @dependency.wont_be :==, @other
    end
  end

  describe "to_s" do
    before do
      @dependency.add_requirement ">= 0.5"
      @dependency.add_requirement "= 0.5.3"
    end

    it "must have a short-form" do
      @dependency.to_s.must_equal "listen"
    end

    it "must have a long-form that includes requirements" do
      @dependency.to_s(true).must_equal "listen (= 0.5.3, >= 0.5)"
    end
  end

  describe "gemspec" do
    it "must return a Gem::Specification" do
      skip
      @dependency.gemspec = Gem::Specification.new
      @dependency.gemspec.must_be_kind_of Gem::Specification
    end
  end

  describe "dependencies" do
    it "must return a Doubleshot::Dependencies::DependencyList" do
      skip
      @dependency.dependencies.must_be_kind_of Doubleshot::Dependencies::DependencyList
    end
  end
end