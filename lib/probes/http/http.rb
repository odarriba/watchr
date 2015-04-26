require 'probes/probe'
require 'net/ping/http'

module Watchr
  # This is an HTTP connectivity probe used to test an HTTP service.
  #
  # Use it to test the status of an HTTP service.
  #
  class HttpProbe < Watchr::Probe
    # Probe name
    PROBE_NAME = "http"
    # Probe description
    PROBE_DESCRIPTION = "It checks the status and delay of an HTTP service."
    # Results' units
    RESULTS_UNITS = "miliseconds"
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
      return t("probes.http.description") if (t("probes.http.description"))
      super
    end

    # Function to get the HTML description of the probe
    #
    # [Returns]
    #   A string with the HTML description of the probe
    #
    def self.description_html
      return t("probes.http.description_html") if (t("probes.http.description_html"))
      super
    end

    # Function to get the units in which are expresed the results
    #
    # [Returns]
    #   A string with the units of the results
    #
    def self.results_units
      return t("probes.http.results_units") if (t("probes.http.results_units"))
      super
    end

    # Function to get the short name of the units in which are expresed 
    # the results
    #
    # [Returns]
    #   A string with the units of the results
    #
    def self.results_units_short
      return t("probes.http.results_units_short") if (t("probes.http.results_units_short"))
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

      valid = true
      # Contains valid port value?
      valid = false if ((config[:port].blank?) || (config[:port].to_i < 1) || (config[:port].to_i > 65535))
      # Contains a valid head_only value?
      valid = false if ((config[:head_only].blank?) || ((config[:head_only].to_i != 0) && (config[:head_only].to_i != 1)))
      # Contains a valid follow_redirect value?
      valid = false if ((config[:follow_redirect].blank?) || ((config[:follow_redirect].to_i != 0) && (config[:follow_redirect].to_i != 1)))
      # Contains a valid path value?
      valid = false if (config[:path].blank?)

      return valid
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
        result.error = t("probes.http.error.config_invalid")

        return result
      end

      # Create the URI
      uri = "http://#{host.address}"
      uri += ":#{probe_config[:port]}" if (probe_config[:port].to_i != 80)

      if (probe_config[:path][0] == "/")
        uri += probe_config[:path]
      else
        uri += "/#{probe_config[:path]}"
      end

      # Create the connection object
      petition = Net::Ping::HTTP.new(uri, probe_config[:port])
      # Configure it
      petition.user_agent = "Watchr"
      petition.follow_redirect = (probe_config[:follow_redirect].to_i == 1)
      petition.get_request = (probe_config[:head_only].to_i == 1)

      # Do the petition
      if (petition.ping)
        # Save the duration
        result.status = HostResult::STATUS_OK
        result.value = petition.duration*1000
      else
        # If the petition ends in error, save the error
        result.status = HostResult::STATUS_ERROR
        result.error = t("probes.http.error.general_error", :err => petition.exception.to_s)
        result.error = t("probes.http.error.connection_refused") if (petition.exception == Errno::ECONNREFUSED)
        result.error = t("probes.http.error.connection_reset") if (petition.exception == Errno::ECONNRESET)
        result.error = t("probes.http.error.redirection_not_followed") if (petition.exception == "Found")
      end

      return result
    end
  end
end