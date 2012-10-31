#!/usr/bin/env jruby

# encoding: utf-8

require_relative "helper"
require "doubleshot/pom"

describe Doubleshot::Pom do
  before do
    @config = Doubleshot.new do |config|
      config.project = "doubleshot"
      config.group   = "org.sam.doubleshot"
      config.version = "1.0"

      config.jar "org.jruby:jruby-complete:jar:1.7.0.RC1"
      config.jar "org.sonatype.aether:aether-api:jar:1.13.1"
      config.jar "org.sonatype.aether:aether-util:jar:1.13.1"
      config.jar("org.sonatype.aether:aether-connector-wagon:1.13.1").exclude("org.sonatype.sisu:sisu-guice")
      config.jar("testing:chaining-exclusions:jar:0.0.1").exclude("testing:exclusion-1").exclude("testing:exclusion-2")

      config.gemspec do |spec|
        spec.summary       = "Build, Dependencies and Testing all in one!"
        spec.description   = "Description"
        spec.author        = "Sam Smoot"
        spec.homepage      = "https://github.com/sam/doubleshot"
        spec.email         = "ssmoot@gmail.com"
        spec.license       = "MIT-LICENSE"
        spec.executables   = [ "doubleshot" ]
      end
    end.config
  end

  it "must generate valid POM markup" do
    Doubleshot::Pom.new(@config).to_s.must_equal <<-EOS.margin
      <?xml version="1.0"?>
      <project xmlns="http://maven.apache.org/POM/4.0.0"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
        <modelVersion>4.0.0</modelVersion>
        <groupId>org.sam.doubleshot</groupId>
        <artifactId>doubleshot</artifactId>
        <version>1.0</version>
        <packaging>pom</packaging>
        <name>doubleshot</name>
        <dependencies>
          <dependency>
            <groupId>org.jruby</groupId>
            <artifactId>jruby-complete</artifactId>
            <type>jar</type>
            <version>1.7.0.RC1</version>
          </dependency>
          <dependency>
            <groupId>org.sonatype.aether</groupId>
            <artifactId>aether-api</artifactId>
            <type>jar</type>
            <version>1.13.1</version>
          </dependency>
          <dependency>
            <groupId>org.sonatype.aether</groupId>
            <artifactId>aether-util</artifactId>
            <type>jar</type>
            <version>1.13.1</version>
          </dependency>
          <dependency>
            <groupId>org.sonatype.aether</groupId>
            <artifactId>aether-connector-wagon</artifactId>
            <type>jar</type>
            <version>1.13.1</version>
            <exclusions>
              <exclusion>
                <groupId>org.sonatype.sisu</groupId>
                <artifactId>sisu-guice</artifactId>
              </exclusion>
            </exclusions>
          </dependency>
          <dependency>
            <groupId>testing</groupId>
            <artifactId>chaining-exclusions</artifactId>
            <type>jar</type>
            <version>0.0.1</version>
            <exclusions>
              <exclusion>
                <groupId>testing</groupId>
                <artifactId>exclusion-1</artifactId>
              </exclusion>
              <exclusion>
                <groupId>testing</groupId>
                <artifactId>exclusion-2</artifactId>
              </exclusion>
            </exclusions>
          </dependency>
        </dependencies>
      </project>
    EOS
  end
end
