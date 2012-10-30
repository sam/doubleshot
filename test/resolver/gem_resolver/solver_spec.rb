#!/usr/bin/env jruby

# encoding: utf-8

require_relative "../../helper"

describe Doubleshot::Resolver::GemResolver::Solver do
  before do
    @graph = Doubleshot::Resolver::GemResolver::Graph.new
    @solver = Doubleshot::Resolver::GemResolver::Solver.new(@graph)
  end

  describe "ClassMethods" do
    describe "::new" do

      it "adds a demand for each element in the array" do
        solver = Doubleshot::Resolver::GemResolver::Solver.new(@graph, ["nginx", "ntp"])
        solver.demands.size.must_equal 2
      end

      describe "when demand_array is an array of array" do
        it "creates a new demand with the name and constraint of each element in the array" do
          solver = Doubleshot::Resolver::GemResolver::Solver.new(@graph, [["nginx", "= 1.2.3"], ["ntp", "= 1.0.0"]])

          solver.demands[0].name.must_equal "nginx"
          solver.demands[0].constraint.to_s.must_equal "= 1.2.3"
          solver.demands[1].name.must_equal "ntp"
          solver.demands[1].constraint.to_s.must_equal "= 1.0.0"
        end
      end

      describe "when demand_array is an array of strings" do
        it "creates a new demand with the name and a default constraint of each element in the array" do
          solver = Doubleshot::Resolver::GemResolver::Solver.new(@graph, ["nginx", "ntp"])

          solver.demands[0].name.must_equal "nginx"
          solver.demands[0].constraint.to_s.must_equal ">= 0"
          solver.demands[1].name.must_equal "ntp"
          solver.demands[1].constraint.to_s.must_equal ">= 0"
        end
      end

      describe "when demand_array is a mix between an array of arrays and an array of strings" do
        let(:demand_array) { [["nginx", "= 1.2.3"], "ntp"] }

        it "creates a new demand with the name and default constraint or constraint of each element in the array" do
          solver = Doubleshot::Resolver::GemResolver::Solver.new(@graph, [["nginx", "= 1.2.3"], "ntp"])

          solver.demands[0].name.must_equal "nginx"
          solver.demands[0].constraint.to_s.must_equal "= 1.2.3"
          solver.demands[1].name.must_equal "ntp"
          solver.demands[1].constraint.to_s.must_equal ">= 0"
        end
      end
    end

    describe "::demand_key" do
      it "returns a symbol containing the name and constraint of the demand" do
        demand = Doubleshot::Resolver::GemResolver::Demand.new(MiniTest::Mock.new, "nginx", "= 1.2.3")
        Doubleshot::Resolver::GemResolver::Solver::demand_key(demand).must_equal :'nginx-= 1.2.3'
      end
    end

    describe "::satisfy_all" do
      before do
        @version_1 = Gem::Version.new("3.1.1")
        @version_2 = Gem::Version.new("3.1.2")

        @constraints = [
          Gem::Requirement.new("> 3.0.0"),
          Gem::Requirement.new("<= 3.1.2")
        ]

        @versions = [
          Gem::Version.new("0.0.1"),
          Gem::Version.new("0.1.0"),
          Gem::Version.new("1.0.0"),
          Gem::Version.new("2.0.0"),
          Gem::Version.new("3.0.0"),
          @version_1,
          @version_2,
          Gem::Version.new("4.1.0")
        ].shuffle
      end

      it "returns all of the versions which satisfy all of the given constraints" do
        solution = Doubleshot::Resolver::GemResolver::Solver::satisfy_all(@constraints, @versions)

        solution.size.must_equal 2
        solution.must_include @version_1
        solution.must_include @version_2
      end

      it "does not return duplicate satisfied versions given multiple duplicate versions" do
        solution = Doubleshot::Resolver::GemResolver::Solver::satisfy_all(@constraints, [@version_1, @version_1, @version_1])

        solution.size.must_equal 1
        solution.must_include @version_1
      end
    end

    describe "::satisfy_best" do
      before do
        @versions = [
          Gem::Version.new("0.0.1"),
          Gem::Version.new("0.1.0"),
          Gem::Version.new("1.0.0"),
          Gem::Version.new("2.0.0"),
          Gem::Version.new("3.0.0"),
          Gem::Version.new("3.1.1"),
          Gem::Version.new("3.1.2"),
          Gem::Version.new("4.1.0")
        ].shuffle
      end

      it "returns the best possible match for the given constraints" do
        Doubleshot::Resolver::GemResolver::Solver::satisfy_best([">= 1.0.0", "< 4.1.0"], @versions)
          .to_s.must_equal "3.1.2"
      end

      it "raises a NoSolutionError error given no version matches a constraint" do
        -> {
          Doubleshot::Resolver::GemResolver::Solver::satisfy_best(">= 5.0.0", [Gem::Version.new("4.1.0")])
        }.must_raise Doubleshot::Resolver::GemResolver::Errors::NoSolutionError
      end
    end
  end

  describe "#resolve" do
    before do
      @graph.artifacts("nginx", "1.0.0")
      @solver.demands("nginx", "= 1.0.0")
    end

    it "returns a solution in the form of a Hash" do
      @solver.resolve.must_be_kind_of Hash
    end
  end

  describe "#demands" do
    describe "given a name and constraint argument" do
      before do
        @name = "nginx"
        @constraint = "~> 0.101.5"
        @demand = @solver.demands(@name, @constraint)
      end

      describe "given the artifact of the given name and constraint does not exist" do
        it "returns a Solve::Demand" do
          @demand.must_be_kind_of Doubleshot::Resolver::GemResolver::Demand
        end

        it "the artifact has the given name" do
          @demand.name.must_equal @name
        end

        it "the artifact has the given constraint" do
          @demand.constraint.to_s.must_equal @constraint
        end

        it "adds an artifact to the demands collection" do
          @solver.demands.size.must_equal 1
        end

        it "the artifact added matches the given name" do
          @solver.demands[0].name.must_equal @name
        end

        it "the artifact added matches the given constraint" do
          @solver.demands[0].constraint.to_s.must_equal @constraint
        end
      end
    end

    describe "given only a name argument" do
      it "returns a demand with a match all version constraint (>= 0)" do
        @solver.demands("nginx").constraint.to_s.must_equal ">= 0"
      end
    end

    describe "given no arguments" do
      it "returns an array" do
        @solver.demands.must_be_kind_of Array
      end

      it "returns an empty array if no demands have been accessed" do
        @solver.demands.size.must_equal 0
      end

      it "returns an array containing a demand if one was accessed" do
        @solver.demands("nginx", "~> 0.101.5")
        @solver.demands.size.must_equal 1
      end
    end

    describe "given an unexpected number of arguments" do
      it "raises an ArgumentError if more than two are provided" do
        -> {
          @solver.demands(1, 2, 3)
        }.must_raise ArgumentError, "Unexpected number of arguments. You gave: 3. Expected: 2 or less."
      end

      it "raises an ArgumentError if a name argument of nil is provided" do
        -> {
          @solver.demands(nil)
        }.must_raise ArgumentError, "A name must be specified. You gave: [nil]."
      end

      it "raises an ArgumentError if a name and constraint argument are provided but name is nil" do
        -> {
          @solver.demands(nil, "= 1.0.0")
        }.must_raise ArgumentError, 'A name must be specified. You gave: [nil, "= 1.0.0"].'
      end
    end
  end

  describe "#add_demand" do
    before do
      @demand = Doubleshot::Resolver::GemResolver::Demand.new(MiniTest::Mock, "ntp")
    end

    it "adds a Solve::Artifact to the collection of artifacts" do
      @solver.add_demand @demand

      @solver.demands.must_include @demand
      @solver.demands.size.must_equal 1
    end

    it "should not add the same demand twice to the collection" do
      @solver.add_demand @demand
      @solver.add_demand @demand

      @solver.demands.must_include @demand
      @solver.demands.size.must_equal 1
    end
  end

  describe "#remove_demand" do
    before do
      @demand = Doubleshot::Resolver::GemResolver::Demand.new(MiniTest::Mock, "ntp")
    end

    describe "given the demand is a member of the collection" do
      before do
        @solver.add_demand @demand
      end

      it "removes the Solve::Artifact from the collection of demands" do
        @solver.remove_demand @demand
        @solver.demands.size.must_equal 0
      end

      it "returns the removed Solve::Artifact" do
        @solver.remove_demand(@demand).must_equal @demand
      end
    end

    it "should return nil given the demand is not a member of the collection" do
      @solver.remove_demand(@demand).must_be_nil
    end
  end

  describe "#has_demand?" do
    before do
      @demand = Doubleshot::Resolver::GemResolver::Demand.new(MiniTest::Mock, "ntp")
    end

    it "returns true if the given Solve::Artifact is a member of the collection" do
      @solver.add_demand @demand

      @solver.has_demand?(@demand).must_equal true
    end

    it "returns false if the given Solve::Artifact is not a member of the collection" do
      @solver.has_demand?(@demand).must_equal false
    end
  end

  describe "solutions" do
    it "chooses the correct artifact for the demands" do
      @graph.artifacts("mysql", "2.0.0")
      @graph.artifacts("mysql", "1.2.0")
      @graph.artifacts("nginx", "1.0.0").depends("mysql", "= 1.2.0")

      result = Doubleshot::Resolver::GemResolver::Solver.new(@graph, [['nginx', '= 1.0.0'], ['mysql']]).resolve

      result.must_equal({"nginx" => "1.0.0", "mysql" => "1.2.0"})
    end

    it "chooses the best artifact for the demands" do
      @graph.artifacts("mysql", "2.0.0")
      @graph.artifacts("mysql", "1.2.0")
      @graph.artifacts("nginx", "1.0.0").depends("mysql", ">= 1.2.0")

      result = Doubleshot::Resolver::GemResolver::Solver.new(@graph, [['nginx', '= 1.0.0'], ['mysql']]).resolve

      result.must_equal({"nginx" => "1.0.0", "mysql" => "2.0.0"})
    end

    it "raises NoSolutionError when a solution cannot be found" do
      @graph.artifacts("mysql", "1.2.0")

      -> {
        Doubleshot::Resolver::GemResolver::Solver.new(@graph, ['mysql', '>= 2.0.0']).resolve
      }.must_raise Doubleshot::Resolver::GemResolver::Errors::NoSolutionError
    end

    it "find the correct solution when backtracking in variables introduced via demands" do
      @graph.artifacts("D", "1.2.0")
      @graph.artifacts("D", "1.3.0")
      @graph.artifacts("D", "1.4.0")
      @graph.artifacts("D", "2.0.0")
      @graph.artifacts("D", "2.1.0")

      @graph.artifacts("C", "2.0.0").depends("D", "= 1.2.0")
      @graph.artifacts("C", "2.1.0").depends("D", ">= 2.1.0")
      @graph.artifacts("C", "2.2.0").depends("D", "> 2.0.0")

      @graph.artifacts("B", "1.0.0").depends("D", "= 1.0.0")
      @graph.artifacts("B", "1.1.0").depends("D", "= 1.0.0")
      @graph.artifacts("B", "2.0.0").depends("D", ">= 1.3.0")
      @graph.artifacts("B", "2.1.0").depends("D", ">= 2.0.0")

      @graph.artifacts("A", "1.0.0").depends("B", "> 2.0.0")
      @graph.artifacts("A", "1.0.0").depends("C", "= 2.1.0")
      @graph.artifacts("A", "1.0.1").depends("B", "> 1.0.0")
      @graph.artifacts("A", "1.0.1").depends("C", "= 2.1.0")
      @graph.artifacts("A", "1.0.2").depends("B", "> 1.0.0")
      @graph.artifacts("A", "1.0.2").depends("C", "= 2.0.0")

      result = Doubleshot::Resolver::GemResolver::Solver.new(@graph, [['A', '~> 1.0.0'], ['D', ">= 2.0.0"]]).resolve

      result.must_equal({"A" => "1.0.1",
                         "B" => "2.1.0",
                         "C" => "2.1.0",
                         "D" => "2.1.0"})
    end

    it "must correctly resolve when one resolution exists but it is not the latest" do
      skip "pending: https://github.com/reset/solve/pull/7"
      
      @graph.artifacts("get-the-old-one", "1.0")
        .depends("locked-mid-1", ">= 0")
        .depends("locked-mid-2", ">= 0")
      @graph.artifacts("get-the-old-one", "0.5")

      @graph.artifacts("locked-mid-1", "2.0").depends("old-bottom", "= 2.0")
      @graph.artifacts("locked-mid-1", "1.3").depends("old-bottom", "= 0.5")
      @graph.artifacts("locked-mid-1", "1.0")

      @graph.artifacts("locked-mid-2", "2.0").depends("old-bottom", "= 2.1")
      @graph.artifacts("locked-mid-2", "1.4").depends("old-bottom", "= 0.5")
      @graph.artifacts("locked-mid-2", "1.0")

      @graph.artifacts("old-bottom", "2.1")
      @graph.artifacts("old-bottom", "2.0")
      @graph.artifacts("old-bottom", "1.0")
      @graph.artifacts("old-bottom", "0.5")

      Doubleshot::Resolver::GemResolver::Solver.new(@graph, ["get-the-old-one"]).resolve.must_equal(
        {
          "get-the-old-one" => "1.0",
          "locked-mid-1" => "1.3",
          "locked-mid-2" => "1.4",
          "old-bottom" => "0.5"
        })
    end

    it "finds the correct solution when there is a circular dependency" do
      @graph.artifacts("A", "1.0.0").depends("B", "1.0.0")
      @graph.artifacts("B", "1.0.0").depends("C", "1.0.0")
      @graph.artifacts("C", "1.0.0").depends("A", "1.0.0")

      result = Doubleshot::Resolver::GemResolver::Solver.new(@graph, [["A", "1.0.0"]]).resolve

      result.must_equal({"A" => "1.0.0",
                         "B" => "1.0.0",
                         "C" => "1.0.0"})
    end

    it "finds the correct solution when there is a p shaped dependency chain" do
      @graph.artifacts("A", "1.0.0").depends("B", "1.0.0")
      @graph.artifacts("B", "1.0.0").depends("C", "1.0.0")
      @graph.artifacts("C", "1.0.0").depends("B", "1.0.0")

      result = Doubleshot::Resolver::GemResolver::Solver.new(@graph, [["A", "1.0.0"]]).resolve

      result.must_equal({"A" => "1.0.0",
                         "B" => "1.0.0",
                         "C" => "1.0.0"})
    end

    it "finds the correct solution when there is a diamond shaped dependency" do
      @graph.artifacts("A", "1.0.0")
        .depends("B", "1.0.0")
        .depends("C", "1.0.0")
      @graph.artifacts("B", "1.0.0")
        .depends("D", "1.0.0")
      @graph.artifacts("C", "1.0.0")
        .depends("D", "1.0.0")
      @graph.artifacts("D", "1.0.0")

      result = Doubleshot::Resolver::GemResolver::Solver.new(@graph, [["A", "1.0.0"]]).resolve

      result.must_equal({"A" => "1.0.0",
                         "B" => "1.0.0",
                         "C" => "1.0.0",
                         "D" => "1.0.0"})
    end

    it "gives an empty solution when there are no demands" do
      result = Doubleshot::Resolver::GemResolver::Solver.new(@graph, []).resolve
      result.must_equal({})
    end

    it "tries all combinations until it finds a solution" do
      @graph.artifacts("A", "1.0.0").depends("B", "~> 1.0.0")
      @graph.artifacts("A", "1.0.1").depends("B", "~> 1.0.0")
      @graph.artifacts("A", "1.0.2").depends("B", "~> 1.0.0")

      @graph.artifacts("B", "1.0.0").depends("C", "~> 1.0.0")
      @graph.artifacts("B", "1.0.1").depends("C", "~> 1.0.0")
      @graph.artifacts("B", "1.0.2").depends("C", "~> 1.0.0")

      @graph.artifacts("C", "1.0.0").depends("D", "1.0.0")
      @graph.artifacts("C", "1.0.1").depends("D", "1.0.0")
      @graph.artifacts("C", "1.0.2").depends("D", "1.0.0")

      # ensure we can't find a solution in the above
      @graph.artifacts("D", "1.0.0").depends("A", "< 0.0.0")

      # Add a solution to the graph that should be reached only after
      #   all of the others have been tried
      #   it must be circular to ensure that no other branch can find it
      @graph.artifacts("A", "0.0.0").depends("B", "0.0.0")
      @graph.artifacts("B", "0.0.0").depends("C", "0.0.0")
      @graph.artifacts("C", "0.0.0").depends("D", "0.0.0")
      @graph.artifacts("D", "0.0.0").depends("A", "0.0.0")

      result = Doubleshot::Resolver::GemResolver::Solver.new(@graph, [["A"]]).resolve

      result.must_equal({ "A" => "0.0.0",
                          "B" => "0.0.0",
                          "C" => "0.0.0",
                          "D" => "0.0.0"})

    end
  end
end