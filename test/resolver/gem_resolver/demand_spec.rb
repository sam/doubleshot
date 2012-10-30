#!/usr/bin/env jruby

# encoding: utf-8

require_relative "../../helper"

describe Doubleshot::Resolver::GemResolver::Demand do
  before do
    @solver = MiniTest::Mock.new
  end

  describe "ClassMethods" do
    describe "::new" do
      it "accepts a string for the constraint parameter" do
        Doubleshot::Resolver::GemResolver::Demand.new(@solver, "listen", "= 0.0.1")
          .constraint.to_s.must_equal "= 0.0.1"
      end

      it "accepts a Gem::Requirement for the constraint parameter" do
        constraint = Gem::Requirement.new("= 0.0.1")

        Doubleshot::Resolver::GemResolver::Demand.new(@solver, "listen", constraint)
          .constraint.must_equal constraint
      end

      describe "when no value for 'constraint' is given" do
        it "uses a default of >= 0" do
          Doubleshot::Resolver::GemResolver::Demand.new(@solver, "listen")
            .constraint.to_s.must_equal ">= 0"
        end
      end
    end
  end

  describe "#delete" do
    describe "given the demand is not the member of a solver" do
      it "returns nil" do
        Doubleshot::Resolver::GemResolver::Demand.new(nil, "listen", "~> 1.0.0")
          .delete.must_be_nil
      end
    end
  end

  describe "equality" do
    before do
      @demand = Doubleshot::Resolver::GemResolver::Demand.new(@solver, "listen", "1.0")
    end

    it "returns true when other is a Doubleshot::Resolver::GemResolver::Demand with the same name and constriant" do
      other_demand = Doubleshot::Resolver::GemResolver::Demand.new(@solver, "listen", "1.0")
      @demand.must_equal other_demand
    end

    it "returns false when other isn't a Solve::Demand" do
      @demand.wont_equal "chicken"
    end

    it "returns false when other is a Solve::Demand with the same name but a different constraint" do
      other_demand = Doubleshot::Resolver::GemResolver::Demand.new(@solver, "listen", "< 3.4.5")

      @demand.wont_equal other_demand
    end

    it "returns false when other is a Solve::Demand with the same constraint but a different name" do
      other_demand = Doubleshot::Resolver::GemResolver::Demand.new(@solver, "chicken", "1.0")

      @demand.wont_equal other_demand
    end
  end
end