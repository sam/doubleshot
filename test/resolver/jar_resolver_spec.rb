#!/usr/bin/env jruby

# encoding: utf-8

require_relative "../helper"

describe Doubleshot::Resolver::JarResolver do
  before do
    @resolver = Doubleshot::Resolver::JarResolver.new(Doubleshot::Resolver::JarResolver::DEFAULT_REPOSITORY)
  end

  describe "fetch" do
    before do
      @dependencies = Doubleshot::Dependencies::JarDependencyList.new
      @dependencies.fetch("com.pyx4j:maven-plugin-log4j:jar:1.0.1")
      @dependencies.fetch("org.springframework:spring-core:jar:3.1.2.RELEASE")
      @dependencies.fetch("org.hibernate:hibernate-core:jar:4.1.7.Final")
    end

    it "must return the same JarDependencyList" do
      @resolver.fetch(@dependencies).must_be_same_as @dependencies
    end

    it "must take a JarDependencyList and populate the path of each JarDependency" do
      @resolver.fetch(@dependencies).each do |dependency|
        dependency.path.wont_be_nil
      end
    end
  end
end