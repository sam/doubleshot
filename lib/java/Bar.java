package org.foo;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Map;
import java.io.IOException;

public class Bar {
  public static String baz() {
    return "SUCCESS!";
  }
  
  public static void main(String[] args) throws Exception {
    System.out.println(Bar.baz());
  }
  
  static final ObjectMapper mapper = new ObjectMapper();
  public static Map<String,Object> parse(String json) throws IOException {
    return mapper.readValue(json, Map.class);
  }
}