require 'probes/probe'

module Watchr
  # This is a dummy Probe for testing pourposes.
  #
  # Use it to test the functionality of the application without
  # load the network.
  #
  # _Note_: It can be used as a model to make your own probes!
  #
  class DummyProbe < Watchr::Probe
    # Probe name
    PROBE_NAME = "dummy"

    # Register this probe
    self.register_this
  end
end