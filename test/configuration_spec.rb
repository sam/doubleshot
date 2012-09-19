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
    
    it "must allow a sample gemspec" do
      begin
        @config.gemspec do |spec|
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
      rescue Exception => e
        fail e
      end
      
      assert true
    end
    
    it "must default the Platform to JRuby" do
      @config.gemspec.platform.os.must_equal "java"
    end
    
    it "must provide sane defaults for rdoc" do
      @config.gemspec.name = "Doubleshot"
      @config.gemspec.rdoc_options.must_equal([
        "--line-numbers",
        "--main", "README.textile",
        "--title", "Doubleshot Documentation",
        "README.textile" ] + @config.source.ruby)
    end
    
    # spec.platform      = Gem::Platform::RUBY
    # spec.files         = `git ls-files`.split("\n") + Dir["target/**/*.class"]
    # spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
    # spec.require_paths = [ "lib" ]
    # spec.rdoc_options = 
  end
  
end