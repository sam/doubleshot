package org.sam.doubleshot.examples.jackson;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Map;
import java.io.IOException;

public class Jackson {
  static final ObjectMapper mapper = new ObjectMapper();
  public static Map<String,Object> parse(String json) throws IOException {
    return mapper.readValue(json, Map.class);
  }
}