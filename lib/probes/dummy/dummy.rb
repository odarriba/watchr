require 'probes/probe'

module Watchr
  # This is a dummy probe for testing pourposes.
  #
  # Use it to test the functionality of the application without
  # load the network.
  #
  # _Note_: It can be used as a model to make your own probes!
  #
  class DummyProbe < Watchr::Probe
    # Probe name
    PROBE_NAME = "dummy"
    # Probe description
    PROBE_DESCRIPTION = "This is a dummy probe that do nothing."
    # Results' units
    RESULTS_UNITS = "seconds"
    # Short name of results' units
    RESULTS_UNITS_SHORT = "s"

    # Register this probe
    self.register_this

    # Function to get the description of the probe
    #
    # [Returns]
    #   A string with the description of the probe
    #
    def self.description
      return t("probes.dummy.description") if (t("probes.dummy.description"))
      super
    end

    # Function to get the HTML description of the probe
    #
    # [Returns]
    #   A string with the HTML description of the probe
    #
    def self.description_html
      return t("probes.dummy.description_html") if (t("probes.dummy.description_html"))
      super
    end

    # Function to get the units in which are expresed the results
    #
    # [Returns]
    #   A string with the units of the results
    #
    def self.results_units
      return t("probes.dummy.results_units") if (t("probes.dummy.results_units"))
      super
    end

    # Function to get the short name of the units in which are expresed 
    # the results
    #
    # [Returns]
    #   A string with the units of the results
    #
    def self.results_units_short
      return t("probes.dummy.results_units_short") if (t("probes.dummy.results_units_short"))
      super
    end

    # Function to check if a probe configuration is valid.
    #
    # [Parameters]
    #   * *config* - A hash of configuration for this probe.
    #
    # [Returns]
    #   A boolean that indicates if a probe configuration hash is valid.
    #
    def self.check_config(config)
      return false if (!config.is_a?(Hash))

      # Contains the dummy value?
      return ((!config[:value].blank?) && (config[:value].to_i >= 0))
    end

    # Function to execute the probe over a host with a configuration.
    #
    # [Parameters]
    #   * *host* - A _Host_ object to test it.
    #   * *probe_config* - A hash with the configuration for the probe defined in the service.
    #
    # [Returns]
    #   A _HostResult_ object with the result of the probe, or nil if no host is received.
    #
    def self.execute(host, probe_config)
      return nil if (!host.is_a?(Host))

      # Create the result object
      result = HostResult.new(:host => host)

      # Is the configuration valid?
      if (!self.check_config(probe_config))
        result.status = HostResult::STATUS_ERROR
        result.error = t("probes.dummy.error.config_invalid")

        return result
      end

      # Assign the dummy value
      result.status = HostResult::STATUS_OK
      result.value = probe_config[:value]

      return result
    end
  end
end