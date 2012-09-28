class Doubleshot::CLI::Commands::Init < Doubleshot::CLI

  def self.summary
    <<-EOS.margin
      Generate a Doubleshot file for your project.
      This command is interactive.
    EOS
  end

  def self.options
    OptionParser.new do |options|
      options.banner = "Usage: doubleshot init [PATH]"
      options.separator ""
      options.separator "  [PATH]      The path to your project directory."
      options.separator "              DEFAULT: Current working directory."
    end
  end

  def self.start(args)
    session = new(args)
    if session.doubleshot_file.exist?
      return puts <<-EOS.margin
        ERROR: A Doubleshot file already exists.
        Rename or delete it to initialize a new one.
      EOS
    end
    session.import_gemspec!
    session.mark_gemspec_for_deletion!
    session.generate_doubleshot_file!

    puts <<-EOS.margin
      We have created a Doubleshot file for your project.

      Please review it and make changes as you see fit. It will
      be used for all the things.
    EOS
    return true
  end

  def initialize(args)
    @path = Pathname(args.empty? ? "." : args.first)
    @config = Doubleshot::Configuration.new
  end

  def doubleshot_file
    Pathname(@path + "Doubleshot")
  end

  def gemspec
    @gemspec ||= Pathname::glob(@path + "*.gemspec").first
  end

  def import_gemspec!
    original = gemspec ? eval_gemspec(gemspec.read) : ::Gem::Specification.new

    @config.gemspec do |spec|
      spec.name         = default original.name,        "THE PROJECT NAME"
      spec.summary      = default original.summary,     "SUMMARIZE ME"
      spec.description  = default original.description, "A VERY DETAILED DESCRIPTION"
      spec.author       = default original.author,      "WHOAMI"
      spec.homepage     = default original.homepage,    "I AM FROM THE INTERNET"
      spec.email        = default original.email,       "ME@EXAMPLE.COM"
      spec.version      = default original.version,     "9000.1"
      spec.license      = default original.license,     "MIT-LICENSE"
      spec.executables  = original.executables
    end
  end

  def eval_gemspec(contents)
    puts "Importing Gemspec..."
    begin
      ::Gem::Specification.from_yaml(contents)
      # Raises ArgumentError if the file is not valid YAML
    rescue ArgumentError, SyntaxError, ::Gem::EndOfYAMLException, ::Gem::Exception
      begin
        eval(contents, Doubleshot::CLI::binding)
      rescue LoadError, SyntaxError => e
        original_line = e.backtrace.find { |line| line.include?(path.to_s) }
        msg  = "There was a #{e.class} while evaluating #{gemspec_pathname.basename}: \n#{e.message}"
        msg << " from\n  #{original_line}" if original_line
        msg << "\n"
        raise GemspecError, msg
      end
    end
  end

  def mark_gemspec_for_deletion!
    if gemspec
      delete_me = gemspec.basename.to_s + ".DELETE_ME"
      gemspec.rename(delete_me)
      puts <<-EOS.margin, "", ""

        IMPORTANT: We have renamed your gemspec to:

          #{delete_me}

        Please delete this file after you have reviewed your Doubleshot file.
        It cannot be used to distribute your project. A valid gemspec will be
        generated for you during the build process so that JAR, Gem, and compiled
        sources are included in your distribution.

        DELETE YOUR GEMSPEC!
      EOS
    end
  end

  def generate_doubleshot_file!
    doubleshot_file.open("w+") do |file|
      file << @config.to_ruby
    end
  end

  private
  def default(value, default_value)
    value.blank? ? default_value : value
  end

end