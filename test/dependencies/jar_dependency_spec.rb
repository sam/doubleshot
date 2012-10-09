#!/usr/bin/env ruby

require_relative "../helper"

describe Doubleshot::Dependencies::JarDependency do
  # ch.qos.logback:logback-core:jar:1.0.6
  # <#JarDependency type: [bundle|jar|zip] artifact: "logback-core" group: "ch.qos.logback" version: "1.0.6">

  it "must only accept a Buildr syntax string with all 4 parts as the name" do
    assert_raises(ArgumentError) do
      Doubleshot::Dependencies::JarDependency.new "ch.qos.logback:logback-core:jar"
    end

    assert_raises(ArgumentError) do
      Doubleshot::Dependencies::JarDependency.new "ch.qos.logback"
    end

    assert_raises(ArgumentError) do
      Doubleshot::Dependencies::JarDependency.new "ch.qos.logback:logback-core:jar:"
    end

    assert_raises(ArgumentError) do
      Doubleshot::Dependencies::JarDependency.new "ch.qos.logback:logback-core::1.0.6"
    end

    assert_raises(ArgumentError) do
      Doubleshot::Dependencies::JarDependency.new "ch.qos.logback::jar:1.0.6"
    end

    assert_raises(ArgumentError) do
      Doubleshot::Dependencies::JarDependency.new ":logback-core:jar:1.0.6"
    end

    assert_raises(ArgumentError) do
      Doubleshot::Dependencies::JarDependency.new ":::"
    end
  end

  it "returns the Buildr syntax string as the name" do
    Doubleshot::Dependencies::JarDependency.new("ch.qos.logback:logback-core:jar:1.0.6")
      .name.must_equal "ch.qos.logback:logback-core:jar:1.0.6"
  end

  it "correctly parses the Buildr syntax string" do
    dependency = Doubleshot::Dependencies::JarDependency.new "ch.qos.logback:logback-core:jar:1.0.6"
    dependency.type.must_equal "jar"
    dependency.artifact.must_equal "logback-core"
    dependency.group.must_equal "ch.qos.logback"
    dependency.version.must_equal "1.0.6"
  end

  it "returns the Buildr syntax string as the long form of to_s" do
    Doubleshot::Dependencies::JarDependency.new("ch.qos.logback:logback-core:jar:1.0.6").to_s(true)
      .must_equal "ch.qos.logback:logback-core:jar:1.0.6"
  end
end