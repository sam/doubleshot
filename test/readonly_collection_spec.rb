#!/usr/bin/env jruby

require_relative "helper"

describe Doubleshot::ReadonlyCollection do

  before do
    @test_set = Set.new
    @test_set << "test string"
    @readonly_collection = Doubleshot::ReadonlyCollection.new(@test_set)
  end

  it "should accept only Enumerables during initialization" do
    assert_raises(ArgumentError) do
      Doubleshot::ReadonlyCollection.new(Object.new)
    end
  end

  describe "equality" do

    before do
      @other_test_set = Set.new
      @other_test_set << "test string"
      @other_readonly_collection = Doubleshot::ReadonlyCollection.new(@other_test_set)
    end

    it "must have semantic equality" do
      assert @readonly_collection.eql?(@other_readonly_collection)
    end

    it "must override the equality operator to consider requirements" do
      @readonly_collection.must_be :==, @other_readonly_collection
    end
  end
end