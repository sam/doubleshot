#!/usr/bin/env jruby

# encoding: utf-8

require_relative "../../helper"

describe Doubleshot::Resolver::GemResolver::Source do

  before do
    @source = Doubleshot::Resolver::GemResolver::Source.new "stub://example.org"
  end

  describe "initialization" do
    it "must initialize with a valid URI" do
      @source.must_be_kind_of Helper::StubSource
    end
  end
end