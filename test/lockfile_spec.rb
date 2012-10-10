#!/usr/bin/env jruby

# encoding: utf-8

require_relative "helper"

describe Doubleshot::Lockfile do

  def lockfile(name = "test.lock")
    Helper::tmp do |tmp|
      (tmp + name).open("w+") do |file|
        file << {}.to_yaml
      end
      yield Doubleshot::Lockfile.new(tmp + name)
    end
  end

  before do
    @jar = Doubleshot::Dependencies::JarDependency.new("ch.qos.logback:logback-core:jar:1.0.6")
    @gem = Doubleshot::Dependencies::GemDependency.new("listen")
    @gem.lock("0.5.3")
  end

  describe "Pathname delegations" do
    it "#exist?" do
      lockfile do |lockfile|
        lockfile.must :exist
      end
    end

    it "#mtime" do
      lockfile do |lockfile|
        lockfile.mtime.must_be_kind_of Time
      end
    end
  end

  describe "path" do
    it "must default to 'Doubleshot.lock'" do
      Doubleshot::Lockfile.new.path.must_equal Pathname("Doubleshot.lock")
    end

    it "must let you specify a path" do
      Doubleshot::Lockfile.new("myproject.lock").path.must_equal Pathname("myproject.lock")
    end

    it "must not create the lockfile on disk implicitly" do
      Doubleshot::Lockfile.new "myproject.lock"
      Pathname("myproject.lock").exist?.wont_equal true
    end
  end

  describe "add" do
    it "must not be empty after adding a dependency" do
      lockfile do |lockfile|
        lockfile.add @jar
        lockfile.wont_be :empty?
      end
    end

    it "must return self" do
      lockfile do |lockfile|
        lockfile.add(@jar).must_be_same_as lockfile
      end
    end

    it "must raise an ArgumentError if passing an abstract Dependency instance" do
      assert_raises(ArgumentError) do
        lockfile do |lockfile|
          lockfile.add Doubleshot::Dependencies::Dependency.new "listen"
        end
      end
    end

    it "must raise if a non-dependency is passed" do
      assert_raises(ArgumentError) do
        lockfile do |lockfile|
          lockfile.add "listen"
        end
      end
    end

    it "must not add a dependency twice" do
      lockfile do |lockfile|
        lockfile.add @jar
        lockfile.add Doubleshot::Dependencies::JarDependency.new("ch.qos.logback:logback-core:jar:1.0.6")
        lockfile.jars.size.must_equal 1
      end
    end

    it "must reject unlocked dependencies" do
      assert_raises(Doubleshot::Lockfile::UnlockedDependencyError) do
        lockfile do |lockfile|
          lockfile.add Doubleshot::Dependencies::GemDependency.new("listen")
        end
      end
    end

    it "must raise an error if it doesn't know how to handle the dependency you've passed" do
      assert_raises(Doubleshot::Lockfile::UnknownDependencyTypeError) do
        dependency = Class.new(Doubleshot::Dependencies::Dependency) do
          def locked?
            true
          end
        end.new("some-raa-tar")

        lockfile do |lockfile|
          lockfile.add(dependency)
        end
      end
    end
  end

  describe "jars" do
    it "must return the list of JAR dependencies" do
      lockfile do |lockfile|
        lockfile.add @jar
        lockfile.jars.size.must_equal 1
      end
    end

    it "must be readonly" do
      lockfile do |lockfile|
        lockfile.jars.must_be_kind_of Doubleshot::ReadonlyCollection
      end
    end
  end

  describe "gems" do
    it "must return the list of Gem dependencies" do
      lockfile do |lockfile|
        lockfile.add @gem
        lockfile.gems.size.must_equal 1
      end
    end

    it "must be readonly" do
      lockfile do |lockfile|
        lockfile.gems.must_be_kind_of Doubleshot::ReadonlyCollection
      end
    end
  end

  describe "jar format" do
    before do
      @lockfile_contents = <<-EOS.margin
        ---
        GEMS: []
        JARS:
          - com.pyx4j:maven-plugin-log4j:jar:1.0.1
          - org.springframework:spring-core:jar:3.1.2.RELEASE
          - org.hibernate:hibernate-core:jar:4.1.7.Final
      EOS
    end

    it "must handle proper YAML format" do
      lockfile "test_good.lock" do |lockfile|
        lockfile.path.open("w+") do |file|
          file << @lockfile_contents
        end
        lockfile.jars.size.must_equal 3
      end
    end

    it "must raise a Psych::SyntaxError for invalid YAML" do
      lockfile "test_bad.lock" do |lockfile|
        lockfile.path.open("w+") do |file|
          file << "<(^.^)> <(^.^<) (>^.^)>" << @lockfile_contents
        end
        -> { lockfile.jars }.must_raise Psych::SyntaxError
      end
    end
  end

  describe "gem format" do
    before do
      @lockfile_contents = <<-EOS.margin
        ---
        GEMS:
          backports (2.6.4): []
          ffi (1.0.11): []
          ffi (1.0.11-java): []
          hitimes (1.1.1): []
          hitimes (1.1.1-java): []
          minitest (3.4.0): []
          minitest-wscolor (0.0.3):
          - minitest (>= 2.3.1)
          multi_json (1.3.6): []
          path (1.3.1): []
          perfer (0.2.0):
          - backports (~> 2.6.3)
          - ffi (~> 1.0.11)
          - hitimes (~> 1.1.1)
          - path (~> 1.3.1)
        JARS: []
      EOS
    end

    it "must handle proper YAML format" do
      skip
      lockfile "test_good.lock" do |lockfile|
        lockfile.path.open("w+") do |file|
          file << @lockfile_contents
        end
        lockfile.gems.size.must_equal 10
      end
    end

    it "must raise a Psych::SyntaxError for invalid YAML" do
      lockfile "test_bad.lock" do |lockfile|
        lockfile.path.open("w+") do |file|
          file << "<(^.^)> <(^.^<) (>^.^)>" << @lockfile_contents
        end
        -> { lockfile.gems }.must_raise Psych::SyntaxError
      end
    end
  end
end
