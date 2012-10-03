#!/usr/bin/env jruby

require_relative "helper"

describe Doubleshot::Dependencies do

  before do
    @dependencies = Doubleshot::Dependencies.new
  end

  describe "gems" do
    it "must be a DependencyList" do
      @dependencies.gems.must_be_kind_of Doubleshot::Dependencies::DependencyList 
    end
  end

  describe "jars" do
    it "must be a DependencyList" do
      @dependencies.jars.must_be_kind_of Doubleshot::Dependencies::DependencyList
    end
  end

  describe "equality" do
    before do
      @other = Doubleshot::Dependencies.new

      # NOTE: #fetch will add the dependency if it does
      # not yet exist in the List.
      @dependencies.gems.fetch "listen"
      @dependencies.jars.fetch "commons-cli:commons-cli:jar:1.2"
    end

    it "must equal if their DependencyLists are equal" do
      @dependencies.wont_equal @other

      @other.gems.fetch "listen"
      @other.jars.fetch "commons-cli:commons-cli:jar:1.2"

      @dependencies.must_equal @other
    end
  end
end
