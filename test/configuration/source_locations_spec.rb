#!/usr/bin/env jruby

require_relative "../helper.rb"

describe Doubleshot::Configuration::SourceLocations do

  # This is only necessary because you can't stub out Mock#to_s,
  # So we use a wrapper to call a different method instead.
  class MockWrapper
    def initialize(mock = MiniTest::Mock.new)
      @mock = mock
    end

    def mock
      @mock
    end

    def expect(*args)
      @mock.expect(*args)
    end

    def verify
      @mock.verify
    end

    def to_s
      @mock.to_string
    end
  end

  before do
    Doubleshot::Configuration::SourceLocations.send(:public, :validate_path)
    @source = Doubleshot::Configuration::SourceLocations.new
  end

  after do
    Doubleshot::Configuration::SourceLocations.send(:private, :validate_path)
  end

  describe "validate_path" do    
    it "must respond_to validate_path" do
      @source.must_respond_to :validate_path
    end

    it "must call to_s on any passed object" do
      mock = MockWrapper.new
      mock.expect(:to_string, "test")
      @source.validate_path mock
      mock.verify
    end

    it "must always return a Pathname" do
      @source.validate_path("test").must_be_kind_of Pathname
    end

    it "must return a valid path" do
      @source.validate_path("lib").exist?.must_equal true

      assert_raises(IOError) do
        @source.validate_path "nothing"
      end

      assert_raises(IOError) do
        @source.validate_path __FILE__
      end

      assert_raises(IOError) do
        @source.validate_path ""
      end
    end
  end

  describe "ruby" do
    it "must respond_to ruby" do
      @source.must_respond_to :ruby
    end

    it "must default to lib" do
      @source.ruby.must_equal Pathname("lib")
    end
  end

  describe "java" do
    it "must respond_to java" do
      @source.must_respond_to :java
    end

    it "must default to ext/java" do
      @source.java.must_equal Pathname("ext/java")
    end
  end

  describe "tests" do
    it "must respond_to tests" do
      @source.must_respond_to :tests
    end

    it "must default to test" do
      @source.tests.must_equal Pathname("test")
    end
  end
end
