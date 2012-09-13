package org.foo;

public class Bar {
  public static int baz() {
    return 1;
  }
  
  public static void main(String[] args) throws Exception {
    System.out.print("The magic number is: %s");
    System.out.println(Bar.baz());
  }
}