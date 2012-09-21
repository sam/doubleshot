#!/usr/bin/env jruby

require_relative "helper.rb"

describe Doubleshot do

  describe "configuration" do
    it "must pass a Configuration object to the block" do
      called = false
      Doubleshot.new do |config|
        called = true
        config.must_be_kind_of Doubleshot::Configuration
      end
      assert called, "block not called"
    end 
  end
  
  it "must respond_to build_gemspec" do
    Doubleshot.new { }.must_respond_to :build_gemspec
  end
  
  it "must generate a valid gemspec" do
    gemspec = Doubleshot.new do |config|
      config.gemspec do |spec|
        spec.name          = "Doubleshot"
        spec.summary       = "Build, Dependencies and Testing all in one!"
        spec.description   = "Description"
        spec.author        = "Sam Smoot"
        spec.homepage      = "https://github.com/sam/doubleshot"
        spec.email         = "ssmoot@gmail.com"
        spec.version       = "1.0"
        spec.license       = "MIT-LICENSE"
        spec.executables   = [ "doubleshot" ]
      end
    end.build_gemspec
    
    eval(gemspec).validate
  end
  
end