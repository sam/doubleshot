#!/usr/bin/env jruby

require "doubleshot/setup"

java_import com.fasterxml.jackson.core.JsonFactory

puts com.fasterxml.jackson.core.JsonFactory.new.inspect
