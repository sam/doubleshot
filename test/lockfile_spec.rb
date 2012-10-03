#!/usr/bin/env jruby

require_relative "helper"

describe Doubleshot::Lockfile do
  
  def lockfile(name = "test.lock")
    Helper::tmp do |tmp|
      yield Doubleshot::Lockfile.new(tmp + name)
    end
  end

  before do
    @jar = Doubleshot::Dependencies::JarDependency.new("ch.qos.logback:logback-core:jar:1.0.6")
    @gem = Doubleshot::Dependencies::GemDependency.new("listen")
    @gem.lock("0.5.3")
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

end