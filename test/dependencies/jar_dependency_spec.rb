#!/usr/bin/env ruby

require_relative "../helper"

describe Doubleshot::Dependencies::JarDependency do
  # ch.qos.logback:logback-core:1.0.6
  # ch.qos.logback:logback-core:jar:1.0.6
  # ch.qos.logback:logback-core:jar:someclassifier:1.0.6
  # <#JarDependency type: [pom|jar|maven-plugin|ejb|war|ear|rar|par|bundle] artifact: "logback-core" group: "ch.qos.logback" version: "1.0.6" classifier: "someclassifier">

  it "must only accept Maven coordinate syntax" do
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

  it "returns a Maven coordinate as the name" do
    Doubleshot::Dependencies::JarDependency.new("ch.qos.logback:logback-core:jar:1.0.6")
      .name.must_equal "ch.qos.logback:logback-core:jar:1.0.6"
  end

  it "correctly parses the Maven coordinate" do
    dependency = Doubleshot::Dependencies::JarDependency.new "ch.qos.logback:logback-core:jar:1.0.6"
    dependency.packaging.must_equal "jar"
    dependency.artifact.must_equal "logback-core"
    dependency.group.must_equal "ch.qos.logback"
    dependency.version.must_equal "1.0.6"
  end

  it "returns a Maven coordinate as the long form of to_s" do
    Doubleshot::Dependencies::JarDependency.new("ch.qos.logback:logback-core:jar:1.0.6")
      .to_s(true).must_equal "ch.qos.logback:logback-core:jar:1.0.6"
  end

  it "returns a 4-part Maven coordinate as the name if you used a 3-part Maven coordinate to create the dependency" do
    Doubleshot::Dependencies::JarDependency.new("ch.qos.logback:logback-core:1.0.6")
      .name.must_equal "ch.qos.logback:logback-core:jar:1.0.6"
  end

  it "returns a 4-part Maven coordinate as the long form of to_s if you used a 3-part Maven coordinate to create the dependency" do
    Doubleshot::Dependencies::JarDependency.new("ch.qos.logback:logback-core:1.0.6")
      .to_s(true).must_equal "ch.qos.logback:logback-core:jar:1.0.6"
  end
end
