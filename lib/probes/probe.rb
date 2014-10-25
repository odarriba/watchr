module Watchr
  # This probe class provides general functions for every probe
  # that inherits from it.
  #
  # It includes auto-registering, and the functions used to return
  # data to the application.
  #  
  class Probe
    # Probe name
    PROBE_NAME = nil
    # Probe description
    PROBE_DESCRIPTION = nil

    # This function allows to register a Probe to be used in
    # the application to probe services.
    #
    # [Returns]
    #   A boolean that indicated the result of the register process
    #
    def self.register_this
      # Returns the result of the register
      return Probes.register_probe(self)

      # If no probe name is defined, return false
      return false
    end

    # Function to get the name of the probe
    #
    # [Returns]
    #   A string with the name of the probe
    #
    def self.name
      return nil if (!self::PROBE_NAME.is_a?(String))
      return self::PROBE_NAME
    end

    # Function to get the description of the probe
    #
    # [Returns]
    #   A string with the description of the probe
    #
    def self.description
      return nil if (!self::PROBE_DESCRIPTION.is_a?(String))
      return self::PROBE_DESCRIPTION
    end

    # Function to get the class object of the probe
    #
    # [Returns]
    #   The class object of the probe
    #
    def self.object
      return self
    end
  end
end