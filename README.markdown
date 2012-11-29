#Doubleshot

Latest test results:

[![Build Status](https://secure.travis-ci.org/sam/doubleshot.png)](http://travis-ci.org/sam/doubleshot)

##Overview

Doubleshot is for Developers using JRuby.

It lets you write Java and Ruby, perform Continuous Testing (meaning whenever a file changes, both Java and Ruby code is sandboxed and reloaded and the appropriate tests run), and package it all up as a Gem or JAR.

It's a substitute for writing your own Maven tasks, declaring Maven Dependencies, managing Ruby dependencies with Bundler, and packaging everything up as a Gem with a Rakefile.

Before Doubleshot you might have a ```Buildfile``` (using Buildr), ```Jarfile``` and ```Gemfile```. Or a ```pom.xml```, ```Gemfile``` and ```Rakefile```. However you slice it, you'd be using multiple tools, with different syntaxes and styles, that required you to run them in a specific order to actually get your project to run.

Doubleshot simplifies all that. One Doubleshot file defines your Gem dependencies *and* your JAR dependencies, and declares how to either test or package it all up as a Gem or a JAR. Once you have a Doubleshot file (take a look at the [examples](https://github.com/sam/doubleshot/tree/master/examples) folder for some basics), then you have a few simple commands you can run to do what you need. Here's the output of ```doubleshot help```:

```
Usage: doubleshot COMMAND [ OPTIONS ]

Summary: Command line tool for creating and managing doubleshot projects.

  doubleshot init     # Generate a Doubleshot file for your project.

  doubleshot test     # A test harness that watches files, builds your
                      # source, and executes tests based on filename
                      # conventions. The location of your tests is
                      # determined by the 'config.source.tests'
                      # attribute of your Doubleshot configuration.

  doubleshot build    # Download all dependencies and compile sources so that you
                      # can use the project directly without installation, such
                      # as with IRB.
                      #
                      # NOTE: Packaging and testing have a dependency on this
                      # command. You don't need to build as a prerequisite.

  doubleshot gem      # Package your project as a Rubygem, bundling any
                      # JAR dependencies and Java classes in with the distribution.

  doubleshot jar      # Package your project as a JAR.

  doubleshot install  # Install your project as a Rubygem.

  doubleshot pom      # Generate a pom.xml based on your Doubleshot file.
```

To get a descriptive ```Doubleshot``` that comments all the options, just run ```doubleshot init``` in your project. It'll read existing ```myproject.gemspec``` and ```pom.xml``` files, and use them to generate a Doubleshot file. Take a look at the ```Doubleshot.example``` file in this project if you just want to read up now.

**Pro-Tip:** Similar to a ```Gem::Specification```, a ```Doubleshot::Configuration``` provides a ```#to_ruby``` method, so that example was generated in IRB from the actual project configuration (the existing ```Doubleshot``` file in the project) like this:

```ruby
require "lib/doubleshot"
Pathname("Doubleshot.example").open("w+") do |example|
  example << Doubleshot::current.config.to_ruby
end
```

##Requirements
* Java 7 or later
* Maven
* JRuby 1.7 or later
* Ruby 1.9 syntax only

##Installation

```
gem install doubleshot
```

##Development

Here's how to get Doubleshot running locally yourself. You'll need Java, Maven and JRuby (1.7.x or -head) installed. Then, clone the repo:

```
git clone git://github.com/sam/doubleshot.git
```

Doubleshot bootstraps its own build using a slightly different process than what is used for projects actually using it. It's a chicken and egg situation. Since Doubleshot depends on some Java code to resolve JAR dependencies, and we can't compile without our dependencies, we can't use Doubleshot's normal code to resolve its own JAR dependencies. That's why Doubleshot has a ```pom.xml``` (generated with the ```doubleshot pom``` command). We shell out to the Maven command line while bootstrapping the build.

All that just to clarify the process. The only thing left you actually need to do at this point is run one of the  ```doubleshot ``` commands to package or test. The internal bootstrapping will take care of the rest:

```
bin/doubleshot test --ci
```

##Project Layout

The *default* project using Doubleshot as its build-tool will have the following layout:

```
/
ext/
java/
    Hello.java       # Java sources appear under the ext/java folder.
lib/
    world.rb         # Ruby sources go in the standard location.
test/
    helper.rb
    hello_spec.rb    # specs match up to lib/**/*.rb or ext/java/**/*.java
    world_spec.rb
Doubleshot           # Your Doubleshot file replaces your project's gemspec
                     # and JBundler's Jarfile.
```

Your tests should be executable and look something like this:

```Ruby
#!/usr/local/env jruby

require_relative "helper.rb"

java_import org.sam.doubleshot.example.Hello

describe Hello do
  it "must rock you" do
    Hello.rock(:you).must_equal true
  end
end
```

...and ```helper.rb``` would look something like this:

```Ruby
require "doubleshot"
require "minitest/autorun"
...
```

## FAQ

### Does Doubleshot support Ruby 1.8.x syntax?

No.

### I get an error about Aether?

If after installing Doubleshot (`gem install doubleshot`) you get the following when trying to run it:

```bash
$ doubleshot build
Performing Doubleshot setup to resolve dependencies...
NameError: missing class or uppercase package name (`org.sam.doubleshot.Aether')
...STACKTRACE_INFORMATION_HERE...
```

Then there's a good change you don't have Java7 installed (the default on OSX is Java6).

Download and install the current version here: http://jdk7.java.net/download.html

##Happy coding!