#!/usr/bin/env jruby

require_relative "../helper"

describe Doubleshot::Dependencies::Dependency do

  before do
    @dependency = Doubleshot::Dependencies::Dependency.new "listen"
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

  describe "Hash contract" do
    # Dependency#name must be immutable since
    # we're using it in Set.
    it "won't respond_to name=" do
      @dependency.wont_respond_to :name=
    end
  end

  describe "equality" do

    it "must have equal hash codes" do
      skip
      @dependency.hash.must_equal @other.hash
    end

    it "must have semantic equality" do
      skip
      assert @dependency.eql?(@other)
    end

    it "must override the equality operator to consider requirements" do
      skip
      @dependency.must_be :==, @other
    end
  end
end
