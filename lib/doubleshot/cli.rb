require_relative "../doubleshot"
require "doubleshot/cli/options"

class Doubleshot
  class CLI

    module Commands
    end

    class << self
      public :binding
    end

    def self.commands
      @commands ||= []
    end

    def self.inherited(target)
      commands << target
    end

    def self.task_name
      name.split("::").last.underscore
    end

    def self.summary
      raise NotImplementedError.new
    end

    def self.options
      raise NotImplementedError.new
    end

    def self.start(args)
      raise NotImplementedError.new
    end

    USAGE = <<-EOS.margin
    Usage: doubleshot COMMAND [ OPTIONS ]

    Summary: Command line tool for creating and managing doubleshot projects.

    EOS

    def self.usage(command_name = "")
      if command_name.blank?
        puts USAGE

        commands.each do |command|
          puts("\n  doubleshot %-8s # %s" % [ command.task_name, command.summary.gsub("\n", "\n" + (" " * 22) + "# ") ])
        end
      elsif command = detect(command_name)
        puts command.options
      else
        puts "\nERROR! COMMAND NOT FOUND: #{command_name}\n\n"
        usage
        exit 1
      end
      exit 0
    end

    def self.detect(command_name)
      commands.detect { |command| command.task_name == command_name }
    end

    def self.start
      if ARGV[0] == "help"
        usage(ARGV[1])
      elsif command = commands.detect { |command| command.task_name == ARGV[0] }
        command.start(ARGV[1..-1])
      else
        usage(ARGV[0])
      end
    end

  end # class CLI
end # class Doubleshot

require_relative "commands/init"
require_relative "commands/test"
require_relative "commands/build"
require_relative "commands/gem"
require_relative "commands/jar"