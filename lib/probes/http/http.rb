require 'probes/probe'

module Watchr
  # This is a dummy Probe for testing pourposes.
  #
  # Use it to test the functionality of the application without
  # load the network.
  #
  # _Note_: It can be used as a model to make your own probes!
  #
  class HttpProbe < Watchr::Probe
    # Probe name
    PROBE_NAME = "http"
    # Probe description
    PROBE_DESCRIPTION = "Performs an HTTP petition and measures the response time."

    # Register this probe
    self.register_this
  end
end