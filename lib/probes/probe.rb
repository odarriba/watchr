module Watchr
  # This probe class provides general functions for every probe
  # that inherits from it.
  #
  # It includes auto-registering, and the functions used to return
  # data to the application.
  #  
  class Probe
    PROBE_NAME = nil

    # This function allows to register a Probe to be used in
    # the application to probe services.
    #
    # [Returns]
    #   A boolean that indicated the result of the register process
    #
    def self.register_this
      # Returns the result of the register
      return Probes.register_probe(self::PROBE_NAME, self) if (!self::PROBE_NAME.blank?)

      # If no probe name is defined, return false
      return false
    end
  end
end