#!/usr/bin/env jruby

require_relative "../helper"

describe Doubleshot::Dependencies::Dependency do

  before do
    @dependency = Doubleshot::Dependencies::Dependency.new "listen"
    @other      = Doubleshot::Dependencies::Dependency.new "listen"
  end

  describe "Hash contract" do

    # Dependency#name must be immutable since
    # we're using it in Set.
    it "won't respond_to name=" do
      @dependency.wont_respond_to :name=
    end

    it "must have equal hash codes for the same name" do
      @dependency.hash.must_equal @other.hash
    end

    it "must be equal if names are equal" do
      @dependency.must_be :eql?, @other
    end
  end

  describe "lock" do
    it "must lock to a specific version" do
      @dependency.lock "0.5.3"
      @dependency.must_be :locked?
    end
  end

  describe "to_s" do
    before do
      @dependency.lock "0.5.3"
    end

    it "must have a short-form" do
      @dependency.to_s.must_equal "listen"
    end

    it "must have a long-form" do
      @dependency.to_s(true).must_equal "listen (0.5.3)"
    end
  end

end