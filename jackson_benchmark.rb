#!/usr/bin/env jruby

require "lib/doubleshot/build"
require "benchmark/ips"
require "json"
java_import com.fasterxml.jackson.databind.ObjectMapper
java_import org.foo.Bar

# We're not trying to benchmark the IO classes, so we'll
# read the data in as a String to be used during parsing.
SAMPLE = File.read("user.json")

Benchmark::ips do |x|
  x.report("JSON") do
    JSON.parse SAMPLE
  end
  
  # This is cheating a bit really, but it's certainly conceivable that
  # you would have a Singleton mapper, and cached target Class in a Java
  # implementation substituting for Ruby's JSON library.
  mapper = ObjectMapper.new
  target = java.util.Map.java_class
  x.report("Jackson") do
    mapper.read_value SAMPLE, target
  end
  
  x.report("Jackson Wrapper") do
    Bar.parse SAMPLE
  end
end