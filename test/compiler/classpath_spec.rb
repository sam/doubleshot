#!/usr/bin/env jruby

require_relative "../helper"

describe Doubleshot::Compiler::Classpath do
  before do
    @classpath = Doubleshot::Compiler::Classpath.new
  end

  describe "add" do
    it "must return self" do
      Helper::tmp do |tmp|
        @classpath.add(tmp.to_s).must_be_same_as @classpath
      end
    end

    it "must raise an exception if the file does not exist" do
      Helper::tmp do |tmp|
        -> do
          @classpath.add(tmp + "asdf")
        end.must_raise(Errno::ENOENT)
      end
    end

    it "must alias to <<" do
      @classpath.must_respond_to :<<
      Helper::tmp do |tmp|
        @classpath << tmp
        @classpath.wont_be_empty
      end
    end
  end

  it "must return Pathnames" do
    Helper::tmp do |tmp|      
      @classpath.add tmp

      @classpath.entries.wont_be_empty
      @classpath.each do |path|
        path.must_be_kind_of Pathname
      end
    end
  end

  it "must return unique paths" do
    Helper::tmp do |tmp|
      @classpath.add(tmp.to_s)
      @classpath.add(tmp.to_s)

      @classpath.size.must_equal 1
    end
  end

  it "must return only directories" do
    Helper::tmp do |tmp|
      dir1 = tmp + "dir1"
      dir2 = tmp + "dir2"

      dir1.mkdir
      dir2.mkdir

      jar1 = dir1.touch "some.jar"
      jar2 = dir2.touch "other.jar"

      @classpath.add dir1
      @classpath.add jar1
      @classpath.add jar2

      @classpath.size.must_equal 2
      @classpath.must_include(tmp + "dir1")
      @classpath.must_include(tmp + "dir2")
    end
  end
end