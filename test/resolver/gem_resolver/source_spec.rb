#!/usr/bin/env jruby

# encoding: utf-8

require_relative "../../helper"

describe Doubleshot::Resolver::GemResolver::Source do

  before do
    @source = Doubleshot::Resolver::GemResolver::Source.new Doubleshot::Resolver::GemResolver::DEFAULT_REPOSITORY
  end

  describe "versions" do
    it "must return a list of available versions for a gem name" do
      versions = @source.versions("rack")
      versions.size.must_be :>, 10
      versions.must_include "1.2.0"
    end
  end

  describe "spec" do
    it "must return a gemspec for a given gem name and version" do
      gemspec = @source.spec "rack", "1.2.0"
      gemspec.name.must_equal "rack"
      gemspec.version.to_s.must_equal "1.2.0"
    end
  end
end