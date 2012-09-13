package org.foo;

public class Bar {
  public static String baz() {
    return "SUCCESS!";
  }
  
  public static void main(String[] args) throws Exception {
    System.out.println(Bar.baz());
  }
}