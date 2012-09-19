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
    @source = Doubleshot::Configuration::SourceLocations.new
  end
  
  describe "ruby" do
    it "must respond_to ruby" do
      @source.must_respond_to :ruby
    end
    
    it "must default to lib" do
      @source.ruby.must_equal Pathname("lib")
    end
    
    it "must be a Pathname" do
      @source.ruby.must_be_kind_of Pathname
    end
    
    describe "writer" do
      it "must respond_to ruby=" do
        @source.must_respond_to :ruby=
      end
      
      it "must call to_s on any passed object" do
        mock = MockWrapper.new
        mock.expect(:to_string, "test")
        @source.ruby = mock
        mock.verify
      end
      
      it "must always return a Pathname" do
        @source.ruby = "test"
        @source.ruby.must_be_kind_of Pathname
      end
      
      it "must return a valid path" do
        @source.ruby.exist?.must_equal true
        
        assert_raises(IOError) do
          @source.ruby = "nothing"
        end
        
        assert_raises(IOError) do
          @source.ruby = __FILE__
        end
        
        assert_raises(IOError) do
          @source.ruby = ""
        end
      end
    end
  end
  
  describe "java" do
    it "must respond_to java" do
      @source.must_respond_to :java
    end
    
    it "must default to ext/java" do
      @source.java.must_equal Pathname("ext/java")
    end
    
    it "must be a Pathname" do
      @source.java.must_be_kind_of Pathname
    end
    
    describe "writer" do
      it "must respond_to java=" do
        @source.must_respond_to :java=
      end
      
      it "must call to_s on any passed object" do  
        mock = MockWrapper.new
        mock.expect(:to_string, "test")
        @source.java = mock
        mock.verify
      end
      
      it "must always return a Pathname" do
        @source.java = "test"
        @source.java.must_be_kind_of Pathname
      end
      
      it "must return a valid path" do
        @source.java.exist?.must_equal true
        
        assert_raises(IOError) do
          @source.java = "nothing"
        end
        
        assert_raises(IOError) do
          @source.java = __FILE__
        end
        
        assert_raises(IOError) do
          @source.java = ""
        end
      end
    end
  end
  
end