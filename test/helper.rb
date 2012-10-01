require_relative "../lib/doubleshot"

require "minitest/autorun"
require "minitest/pride"
require "minitest/wscolor"

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