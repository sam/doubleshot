require_relative "../lib/doubleshot"

require "minitest/autorun"
require "minitest/pride"
require "minitest/wscolor"

module MiniTest
  module Assertions
    def assert_predicate o1, op, msg = nil
      msg = message(msg) { "Expected #{mu_pp(o1)} to be #{op}" }
      if !o1.respond_to?(op) && o1.respond_to?("#{op}?")
        assert o1.__send__("#{op}?"), msg
      else
        assert o1.__send__(op), msg
      end
    end
  end

  module Expectations
    # This is for aesthetics, so instead of:
    #   something.must_be :validate
    # Or:
    #   something.validate.must_equal true
    # Which are both terribly ugly, we can:
    #   something.must :validate
    infect_an_assertion :assert_operator, :must, :reverse
  end
end

module Helper
  def self.tmp(path = "tmp")
    dir = Pathname(path.to_s)
    dir.rmtree if dir.exist?
    dir.mkpath

    yield dir

  ensure
    dir.rmtree if dir.exist?
  end
end