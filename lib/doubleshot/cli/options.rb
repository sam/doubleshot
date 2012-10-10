require "optparse"
require "ostruct"

class Doubleshot
  class CLI
    class Options < OpenStruct

      def self.__forward__(*methods)
        methods.each do |method|
          define_method(method) do |*args, &b|
            @parser.send(method, *args, &b)
          end
        end
      end

      OptionParser.instance_methods(false).each do |method_name|
        __forward__ method_name
      end

      def initialize
        super
        @parser = OptionParser.new
        yield self
      end

      def parse!(args)
        self.args = @parser.parse! args
        self
      end

      def to_s
        @parser.to_s
      end
    end
  end
end