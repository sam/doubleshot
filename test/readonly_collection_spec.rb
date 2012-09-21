#!/usr/bin/env jruby

require_relative "helper"

describe Doubleshot::ReadonlyCollection do
  it "should accept only Enumerables during initialization" do
    assert_raises(ArgumentError) do
      Doubleshot::ReadonlyCollection.new(Object.new)
    end
  end
end