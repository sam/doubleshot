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

      __forward__ :banner, :separator, :on

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