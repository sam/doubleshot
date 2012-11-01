#!/usr/bin/env jruby

# To run this example, first build the source:
#   doubleshot build
# Then directly execute it:
#   ./benchmark.rb

# Since we don't intend to distribute this example
# as it's own Gem, we'll just require doubleshot/setup
# directly to ensure our dependencies are resolved,
# and that our code is built and added to $CLASSPATH.
# You wouldn't normally reference Doubleshot anywhere
# except your tests if you want to be able to direct-
# execute them. If you're using the `doubleshot test`
# command exclusively, then not even that would be
# necessary.
require "doubleshot/setup"

# If distributed as a Gem you would:
# begin
#   # "jackson" is our project-name, so our JAR's
#   # name containing our compiled code and all
#   # bundled dependencies is "jackson.jar":
#   require "jackson.jar"
# rescue LoadError
#   # Rescue the LoadError if you want to be able
#   # to run tests and what-not during development.
#   # You don't need to do anything in particular here,
#   # but we'll throw a warning just in case:
#   warn <<-EOS
# WARN: jackson.jar not loaded
# This probably means you're executing directly,
# without a Gem. If you get this message from your
# gem, then the distribution is broken.
# EOS
# end

require "perfer"
require "json"
java_import com.fasterxml.jackson.databind.ObjectMapper
java_import org.sam.doubleshot.examples.jackson.Jackson

SAMPLE = <<EOS.strip
{
  "name" : { "first" : "Joe", "last" : "Sixpack" },
  "gender" : "MALE",
  "verified" : false
}
EOS

Perfer::session "JSON Parsing" do |x|
  x.iterate("JSON") do
    JSON.parse SAMPLE
  end

  # This is cheating a bit really, but it's certainly conceivable that
  # you would have a Singleton mapper, and cached target Class in a Java
  # implementation substituting for Ruby's JSON library.
  mapper = ObjectMapper.new
  target = java.util.Map.java_class
  x.iterate("Jackson") do
    mapper.read_value SAMPLE, target
  end

  x.iterate("Jackson Wrapper") do
    Jackson.parse SAMPLE
  end
end.run

__END__

#########################################################
## perfer results:

Taking 10 measurements of at least 1.0s
JSON            7.997 µs/i ± 0.814 (10.2%) <=> 125054 ips
Jackson         4.180 µs/i ± 0.594 (14.2%) <=> 239222 ips
Jackson Wrapper 4.712 µs/i ± 1.239 (26.3%) <=> 212228 ips

#########################################################
## perfer results with a much larger (26K) document:

Taking 10 measurements of at least 1.0s
JSON            1.041 ms/i ± 0.088 ( 8.4%) <=> 960 ips
Jackson         356.8 µs/i ± 27.36 ( 7.7%) <=> 2803 ips
Jackson Wrapper 350.9 µs/i ± 2.912 ( 0.8%) <=> 2850 ips
