class Time
  
  def self.measure
    start = now
    yield
    now - start
  end
end