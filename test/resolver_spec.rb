#!/usr/bin/env jruby

# encoding: utf-8

require_relative "helper"

describe Doubleshot::Resolver do
  describe "repositories" do
    it "must initialize with a list of repository URIs"  do
      resolver = Doubleshot::Resolver.new("http://localhost")
      resolver.repositories.each do |repository|
        repository.must_be_kind_of URI
      end
    end

    it "must return a ReadonlyCollection" do
      Doubleshot::Resolver.new("http://localhost").repositories.must_be_kind_of Doubleshot::ReadonlyCollection
    end

    it "must require at least one repository" do
      -> { Doubleshot::Resolver.new }.must_raise(ArgumentError)
    end
  end

end