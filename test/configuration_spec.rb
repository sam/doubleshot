#!/usr/bin/env jruby

require_relative "helper.rb"

describe Doubleshot::Configuration do
  
  before do
    @config = Doubleshot::Configuration.new
  end
  
  describe "gemspec" do
    it "must respond_to gemspec" do
      @config.must_respond_to :gemspec
    end
  
    it "must be a Gem::Specification" do
      @config.gemspec.must_be_kind_of Gem::Specification
    end
    
    it "must accept a block" do
      @config.method(:gemspec).parameters.detect do |parameter|
        parameter.first == :block
      end.wont_be_nil
    end
  end
  
end