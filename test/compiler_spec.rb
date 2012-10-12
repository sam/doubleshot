#!/usr/bin/env jruby

require_relative "helper"

describe Doubleshot::Compiler do

  def compile
    Helper::tmp do |tmp|
      source = tmp + "java"
      source.mkdir

      target = tmp + "target"
      target.mkdir

      (source + "Cow.java").open("w+") do |cow|
        cow << <<-EOS.margin
        package org.sam.doubleshot;

        public class Cow {
          public Cow() {}

          public String moo() {
            return "MOO!";
          }
        }
        EOS
      end

      sleep 1 # Sleep because file mtime does not
      # have enough resolution to allow us to accurately
      # detect changes quickly enough in tests. It's
      # very unlikely you'd ever run into this in your
      # actual work.
      yield Doubleshot::Compiler.new(source, target)
    end
  end

  it "must accept source and target paths" do
    compiler = Doubleshot::Compiler.new "ext/java", "target"
    compiler.source.must_equal Pathname("ext/java")
    compiler.target.must_equal Pathname("target")
  end

  describe "#pending?" do

    it "wont be pending after a build" do
      compile do |compiler|
        compiler.build!
        compiler.wont_be :pending
      end
    end

    it "must be pending if target has not been built" do
      compile do |compiler|
        compiler.must_be :pending
      end
    end

    it "must be pending if existing source is modified" do
      compile do |compiler|
        compiler.build!
        sleep 1 # Refer to comment for 'sleep 1' in #compile helper
        (compiler.source + "Cow.java").open("w+") do |cow|
          cow << <<-EOS.margin
          package org.sam.doubleshot;

          public class Cow {
            public Cow() {}

            public String moo() {
              return "FRANCIS!";
            }
          }
          EOS
        end

        compiler.must_be :pending
      end
    end

    it "must be pending if a new source file is added" do
      compile do |compiler|
        compiler.build!
        sleep 1 # Refer to comment for 'sleep 1' in #compile helper
        (compiler.source + "Moo.java").open("w+") do |cow|
          cow << <<-EOS.margin
          package org.sam.doubleshot;

          public class Moo {
            public Moo() {}

            public String moo() {
              return "COW!";
            }
          }
          EOS
        end

        compiler.must_be :pending
      end
    end
  end

  it "must compile a cow" do
    compile do |compiler|
      # We pass the add_target_to_current_classpath=true option
      # so that we can then load a Cow instance a few lines
      # further down.
      compiler.build!(true).must_be_same_as compiler

      cow = compiler.target + "org/sam/doubleshot/Cow.class"
      cow.must :exist

      org.sam.doubleshot.Cow.new.moo.must_equal "MOO!"
    end
  end

  it "must have a classpath" do
    compiler = Doubleshot::Compiler.new "ext/java", "target"
    compiler.classpath.must_be_kind_of Doubleshot::Compiler::Classpath
  end

end