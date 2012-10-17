// Build with:
//   doubleshot jar
// Execute with:
//   java -jar target/hello_ruby_world.jar

package org.ckrailo.doubleshot.examples.hello_ruby_world;

public class HelloRubyWorld {
  public static void main(String[] args) {
    System.out.println("Hello World!");
    org.jruby.Ruby.newInstance().executeScript("require 'lib/hello_ruby_world.rb'", "lib/hello_ruby_world.rb");
  }
}
