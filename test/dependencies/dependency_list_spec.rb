#!/usr/bin/env jruby

require_relative "../helper"

describe Doubleshot::Dependencies::DependencyList do
  
  before do
    @list = Doubleshot::Dependencies::DependencyList.new
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
      dependency = Doubleshot::Dependencies::Dependency.new "listen"
      @list.add dependency
      @list.must_include dependency
    end
  end
      
end