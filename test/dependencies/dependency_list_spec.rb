#!/usr/bin/env jruby

require_relative "../helper"

describe Doubleshot::Dependencies::DependencyList do

  before do
    @list = Doubleshot::Dependencies::DependencyList.new
    @dependency = Doubleshot::Dependencies::Dependency.new "listen"
  end

  it "must be Enumerable" do
    @list.must_be_kind_of Enumerable
  end

  describe "+" do
    it "must allow you to concatenate two collections" do
      one = Doubleshot::Dependencies::DependencyList.new
      two = Doubleshot::Dependencies::DependencyList.new

      listen    = one.fetch "listen"
      minitest  = two.fetch "minitest"

      (one + two).entries.must_equal [ listen, minitest ]
    end

    it "must raise an ArgumentError if the lists are not the same type" do
      one = Doubleshot::Dependencies::DependencyList.new
      two = Doubleshot::Dependencies::GemDependencyList.new

      listen    = one.fetch "listen"
      minitest  = two.fetch "minitest"

      -> { one + two }.must_raise ArgumentError
    end
  end

  describe "add" do
    it "must only accept Dependency instances" do
      assert_raises(ArgumentError) do
        @list.add(Object.new)
      end
    end

    it "must include an added dependency" do
      @list.add @dependency
      @list.must_include @dependency
    end

    it "must not add duplicate dependencies" do
      @list.add @dependency
      @list.add @dependency
      @list.size.must_equal 1
    end

    it "must always return self for chainability" do
      @list.add(@dependency).must_equal @list
    end
  end

  describe "fetch" do
    it "must find matching dependencies by name" do
      @list.add @dependency
      @list.fetch("listen").must_equal @dependency
    end

    it "must always return a dependency" do
      @list.fetch("example").must_be_kind_of Doubleshot::Dependencies::Dependency
    end
  end

  describe "equality" do
    before do
      @other = Doubleshot::Dependencies::DependencyList.new
      @other_dependency = Doubleshot::Dependencies::Dependency.new "listen"
    end

    it "must be equal if both are empty" do
      @list.must_be :==, @other
    end

    it "must be equal if other list have equal dependencies" do
      @list.add @dependency
      @other.add @other_dependency

      @list.must_be :==, @other
    end

    it "wont be equal" do
      @list.add @dependency
      @list.wont_be :==, @other
    end
  end

end
