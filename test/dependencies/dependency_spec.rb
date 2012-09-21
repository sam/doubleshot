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

end
