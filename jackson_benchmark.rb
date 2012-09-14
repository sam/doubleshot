#!/usr/bin/env jruby

require "lib/doubleshot/build"
require "perfer"
require "json"
java_import com.fasterxml.jackson.databind.ObjectMapper
java_import org.foo.Bar

# We're not trying to benchmark the IO classes, so we'll
# read the data in as a String to be used during parsing.
SAMPLE = File.read("user.json")

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
    Bar.parse SAMPLE
  end
end

__END__

Calculating -------------------------------------
                JSON      3314 i/100ms
             Jackson      8639 i/100ms
     Jackson Wrapper     11565 i/100ms
-------------------------------------------------
                JSON   122413.1 (±8.6%) i/s -     510356 in   5.012000s
             Jackson   239300.3 (±23.1%) i/s -     984846 in   4.997000s
     Jackson Wrapper   248393.7 (±26.5%) i/s -     994590 in   5.003000s