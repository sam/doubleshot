#!/usr/bin/env jruby

require_relative "helper"

describe Doubleshot::Dependencies do

  before do
    @dependencies = Doubleshot::Dependencies.new
  end

  describe "gems" do
    it "must respond_to gems" do
      @dependencies.must_respond_to :gems
    end

    it "must be a DependencyList" do
      @dependencies.gems.must_be_kind_of Doubleshot::Dependencies::DependencyList 
    end
  end

  describe "jars" do
    it "must respond_to jars" do
      @dependencies.must_respond_to :jars
    end

    it "must be a DependencyList" do
      @dependencies.jars.must_be_kind_of Doubleshot::Dependencies::DependencyList
    end
  end


end
