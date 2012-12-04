require 'rexml/document'

class Doubleshot::CLI::Commands::Init < Doubleshot::CLI

  def self.summary
    <<-EOS.margin
      Generate a Doubleshot file for your project.
    EOS
  end

  def self.options
    Options.new do |options|
      options.banner = "Usage: doubleshot init [PATH]"
      options.separator ""
      options.separator "  [PATH]      The path to your project directory."
      options.separator "              DEFAULT: Current working directory."
      options.separator ""
      options.separator "Summary: #{summary}"
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

    session.import_pom! if session.pom_file.exist?

    session.generate_doubleshot_file!

    puts <<-EOS.margin
      We have created a Doubleshot file for your project.

      Please review it and make changes as you see fit. It will
      be used for all the things.
    EOS
    return 0
  end

  def initialize(args)
    @path = Pathname(args.empty? ? "." : args.first)
    @config = Doubleshot::Configuration.new
  end

  def doubleshot_file
    Pathname(@path + "Doubleshot")
  end

  def pom_file
    Pathname(@path + "pom.xml")
  end

  def gemspec
    @gemspec ||= Pathname::glob(@path + "*.gemspec").first
  end

  def import_gemspec!
    original = gemspec ? eval_gemspec(gemspec.read) : ::Gem::Specification.new

    @config.project = default original.name,    "THE PROJECT NAME"
    @config.version = default original.version, "9000.1"

    @config.gemspec do |spec|
      spec.summary     = default original.summary,     "SUMMARIZE ME"
      spec.description = default original.description, "A VERY DETAILED DESCRIPTION"
      spec.author      = default original.author,      "WHOAMI"
      spec.homepage    = default original.homepage,    "I AM FROM THE INTERNET"
      spec.email       = default original.email,       "ME@EXAMPLE.COM"
      spec.license     = default original.license,     "MIT-LICENSE"
      spec.executables = original.executables
    end

    original.runtime_dependencies.each do |dependency|
      @config.gem dependency.name, *dependency.requirements_list
    end

    @config.development do
      original.development_dependencies.each do |dependency|
        @config.gem dependency.name, *dependency.requirements_list
      end
    end
  end

  def import_pom!
    pom_document = REXML::Document.new pom_file.open

    project = pom_document.get_text("project/artifactId")
    @config.project = project if (@config.project.nil? or @config.project == "THE PROJECT NAME") and not project.nil?

    @config.group = pom_document.get_text("project/groupId")

    version = pom_document.get_text("project/version")
    @config.version = version if (@config.version.nil? or @config.version == "9000.1") and not version.nil?

    pom_document.elements.each("project/dependencies/dependency") do |pom_dependency|
      group_id = pom_dependency.get_text("groupId")
      artifact_id = pom_dependency.get_text("artifactId")
      version = pom_dependency.get_text("version")

      @config.jar "#{group_id}:#{artifact_id}:jar:#{version}"
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
        raise Gem::InvalidSpecificationException, "There was a #{e.class} while evaluating gemspec: \n#{e.message}"
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