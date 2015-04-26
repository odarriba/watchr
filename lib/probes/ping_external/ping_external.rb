require 'probes/probe'
require 'net/ping/external'

module Watchr
  # This is a general ping probe to test general connectivity using the operating system ping utility.
  #
  # Use it to test the connectivity between the app server and the target
  #
  class PingExternalProbe < Watchr::Probe
    # Probe name
    PROBE_NAME = "ping_external"
    # Probe description
    PROBE_DESCRIPTION = "It uses the ping utility provided by the operating system to test the connectivity to a remote host."
    # Results' units
    RESULTS_UNITS = "milliseconds"
    # Short name of results' units
    RESULTS_UNITS_SHORT = "ms"

    # Register this probe
    self.register_this

    # Function to get the description of the probe
    #
    # [Returns]
    #   A string with the description of the probe
    #
    def self.description
      return t("probes.ping_external.description") if (t("probes.ping_external.description"))
      super
    end

    # Function to get the HTML description of the probe
    #
    # [Returns]
    #   A string with the HTML description of the probe
    #
    def self.description_html
      return t("probes.ping_external.description_html") if (t("probes.ping_external.description_html"))
      super
    end

    # Function to get the units in which are expresed the results
    #
    # [Returns]
    #   A string with the units of the results
    #
    def self.results_units
      return t("probes.ping_external.results_units") if (t("probes.ping_external.results_units"))
      super
    end

    # Function to get the short name of the units in which are expresed 
    # the results
    #
    # [Returns]
    #   A string with the units of the results
    #
    def self.results_units_short
      return t("probes.ping_external.results_units_short") if (t("probes.ping_external.results_units_short"))
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
      # Contains valid count and interval value?
      return ((!config[:count].blank?) && (config[:count].to_i >= 1) && (!config[:interval].blank?) && (config[:interval].to_f >= 0.2))
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
        result.error = t("probes.ping_external.error.config_invalid")

        return result
      end

      # Create the ping object
      ping = Net::Ping::External.new()
      count = probe_config[:count].to_i
      interval = probe_config[:interval].to_f

      if (ping.ping(host.address, count, interval))
        # Save the duration
        result.status = HostResult::STATUS_OK
        result.value = ((ping.duration-(interval*(count-1)))/count)*1000
      else
        # If the ping ends in error, save the error
        result.status = HostResult::STATUS_ERROR
        result.error = ping.exception
        result.error = "Unknown error" if (result.error.blank?)
      end

      return result
    end
  end
end