#!/usr/local/env jruby

require_relative "helper.rb"

describe Hello do
  it "must rock you" do
    Hello.rock(:you).must_equal true
  end
end