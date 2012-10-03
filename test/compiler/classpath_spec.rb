#!/usr/bin/env jruby

require_relative "../helper"

describe Doubleshot::Compiler::Classpath do
  describe "add" do
    it "must return self" do
      Helper::tmp do |tmp|
        classpath = Doubleshot::Compiler::Classpath.new
        classpath.add(tmp.to_s).must_be_same_as classpath
      end
    end

    it "must raise an exception if the file does not exist" do
      Helper::tmp do |tmp|
        -> do
          Doubleshot::Compiler::Classpath.new.add(tmp + "asdf")
        end.must_raise(Errno::ENOENT)
      end
    end
  end
end