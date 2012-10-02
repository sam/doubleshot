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

end