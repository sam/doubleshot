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

  describe "add" do
    it "must respond_to add" do
      @list.must_respond_to :add
    end

    it "must only accept Dependency instances" do
      assert_raises(ArgumentError) do
        @list.add(Object.new)
      end
    end

    it "must include an added dependency" do
      @list.add @dependency
      @list.must_include @dependency
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

end
