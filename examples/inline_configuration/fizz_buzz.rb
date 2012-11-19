#!/usr/bin/env jruby

# This example demonstrates using Doubleshot inline,
# declaring and resolving dependencies without having
# to create a separate Doubleshot file. Useful for
# little one-off scripts like this. For example:
#   As long as you have doubleshot installed, any
# single-file Gist would be self-executable, defining
# it's dependencies inline.
require "doubleshot"

Doubleshot.new do |config|
  config.gem "perfer", "= 0.2.0"
end.setup!

require "perfer"
require "stringio"
require "singleton"

class Solutions
  include Singleton

  def initialize
    @solutions = []
    @names = {}
  end

  def add(name, &b)
    @solutions << b
    @names[b] = name
  end

  def benchmark!(warmup_jruby = false)
    raise StandardError.new("Solutions do not match!") unless valid?

    if warmup_jruby
      @solutions.each do |solution|
        puts "Warming up: #{@names[solution].inspect}"
        # JRuby is going to try to optimize out
        # a method after 10,050 iterations IIRC.
        # These execute so quickly though, that
        # we're just going to multiple that a bit.
        (10_050 * 10).times do
          solution.call StringIO.new
        end
      end
      puts "Done warming up solutions."
    end
    
    Perfer::session "FizzBuzz" do |x|
      @solutions.each do |solution|
        x.iterate(@names[solution]) do
          solution.call StringIO.new
        end
      end
    end.run
  end

  private
  def valid?
    raise NoSolutionsDefinedError.new if @solutions.empty?
    return true if @solutions.size == 1

    reference = render(@solutions[0]).string
    @solutions[1..-1].all? { |solution| render(solution).string == reference }
  end

  def render(solution)
    buffer = StringIO.new
    solution.call(buffer)
    buffer
  end

  class NoSolutionsDefinedError < StandardError
  end
end

def solution(name, &b)
  Solutions.instance.add(name, &b)
end

solution "Reference" do |out|
  def self.multiple_of_3(number)
    number % 3 == 0
  end

  def self.multiple_of_5(number)
    number % 5 == 0
  end
  1.upto(100) do |i|
    output = ""

    if !multiple_of_3(i) && !multiple_of_5(i)
      output = i
    else
      output << "Fizz" if multiple_of_3(i)
      output << "Buzz" if multiple_of_5(i)
    end

    out.puts output
  end
end

# In SolutionTwo we inline the modulo operations,
# and re-order the conditionals to avoid evaluating
# the same expression more than once.
solution "Evaluate Once" do |out|
  1.upto(100) do |i|
    if i % 3 == 0
      if i % 5 == 0
        out.puts "FizzBuzz"
      else
        out.puts "Fizz"
      end
    else
      if i % 5 == 0
        out.puts "Buzz"
      else
        out.puts i
      end
    end
  end
end

# In SolutionThree we optimize SolutionTwo further
# by avoiding the modulo operations, and switching
# to a while loop to avoid the dispatch overhead of
# the block iterator.
#
# So far our solutions are all (mostly) fundamentally
# the same, each step simply inlining operations.
# The only real algorithmic advancement is to re-order
# the conditionals to avoid needing to evaluate the
# "3" or "5" case more than once when only one of those
# is true.
#
# NOTE: This solution is the best performing, by a
# pretty good margin, around two-to-one over the short,
# idiomatic solutions. Just goes to show,
# method-dispatch (yes, including block-yielding) is
# the enemy of fast Ruby code.
solution "While Loop" do |out|
  i = 1
  threes = 1
  fives = 1

  while i < 101
    if threes == 3
      threes = 0
      if fives == 5
        fives = 0
        out.puts "FizzBuzz"
      else
        out.puts "Fizz"
      end
    else
      if fives == 5
        fives = 0
        out.puts "Buzz"
      else
        out.puts i
      end
    end

    threes += 1
    fives += 1
    i += 1
  end
end

# This solution by Daniel Martin is cuourtesy of Ruby Quiz:
#   http://www.rubyquiz.com/quiz126.html
solution "Martinization" do |out|
  (1..100).each do |i|
    x = ""
    x += "Fizz" if i % 3 == 0
    x += "Buzz" if i % 5 == 0
    out.puts( x.empty? ? i : x )
  end
end

# This is the same as SolutionFour, but with an experiment
# to optimize out the temporary string:
solution "No Temporary String" do |out|
  alt = nil

  (1..100).each do |i|
    if i % 3 == 0
      alt = true
      out.print "Fizz"
    end

    if i % 5 == 0
      alt = true
      out.print "Buzz"
    end

    if alt
      alt = nil
      out << $/
    else
      out.puts i
    end
  end
end

# Another alternative to solution four, seeing if
# precalculating the range to an Array improves
# performance at all (since it's a small range),
# there's no real reason not to, but depending
# on the implementation of Range#to_a, we may
# not avoid calling Fixnum#succ anyway, so it
# might be a useless exercise.
solution "Precalculated Array" do |out|
  (1..100).to_a.each do |i|
    x = ""
    x += "Fizz" if i % 3 == 0
    x += "Buzz" if i % 5 == 0
    out.puts( x.empty? ? i : x )
  end
end

Solutions.instance.benchmark! !!ARGV[0]

__END__

#########################################################
Output of solutions match? true
Session FizzBuzz with jruby 1.7.0 (1.9.3p203) 2012-10-22 ff1ebbe on Java HotSpot(TM) 64-Bit Server VM 1.7.0_04-b21 [darwin-x86_64]

Taking 10 measurements of at least 1.0s
Reference           87.38 µs/i ± 2.371 ( 2.7%) <=> 11443 ips
Evaluate Once       49.78 µs/i ± 0.274 ( 0.6%) <=> 20085 ips
While Loop          40.81 µs/i ± 0.833 ( 2.0%) <=> 24500 ips
Martinization       58.31 µs/i ± 0.281 ( 0.5%) <=> 17148 ips
No Temporary String 47.81 µs/i ± 0.220 ( 0.5%) <=> 20916 ips
Precalculated Array 59.24 µs/i ± 1.466 ( 2.5%) <=> 16879 ips