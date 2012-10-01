module Kernel
  def silence
    $VERBOSE, old_verbosity = nil, $VERBOSE
    yield
  ensure
    $VERBOSE = old_verbosity
  end
end