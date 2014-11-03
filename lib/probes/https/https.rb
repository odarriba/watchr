require 'probes/probe'
require 'net/ping/http'

module Watchr
  # This is an HTTP connectivity probe used to test an HTTP service.
  #
  # Use it to test the status of an HTTP service.
  #
  class HttpsProbe < Watchr::Probe
    # Probe name
    PROBE_NAME = "https"
    # Probe description
    PROBE_DESCRIPTION = "It checks the status and delay of an HTTPS service."

    # Register this probe
    self.register_this

    # Function to get the description of the probe
    #
    # [Returns]
    #   A string with the description of the probe
    #
    def self.description
      return t("probes.https.description") if (t("probes.https.description"))
      super
    end

    # Function to get the HTML description of the probe
    #
    # [Returns]
    #   A string with the HTML description of the probe
    #
    def self.description_html
      return t("probes.https.description_html") if (t("probes.https.description_html"))
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
      # Contains a valid path value?
      valid = false if (config[:path].blank?)
      # Contains a valid head_only value?
      valid = false if ((config[:head_only].blank?) || ((config[:head_only].to_i != 0) && (config[:head_only].to_i != 1)))
      # Contains a valid follow_redirect value?
      valid = false if ((config[:follow_redirect].blank?) || ((config[:follow_redirect].to_i != 0) && (config[:follow_redirect].to_i != 1)))
      # Contains a valid follow_redirect value?
      valid = false if ((config[:check_certificate].blank?) || ((config[:check_certificate].to_i != 0) && (config[:check_certificate].to_i != 1)))

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
        result.error = t("probes.https.error.config_invalid")

        return result
      end

      # Create the URI
      uri = "https://#{host.address}"
      uri += ":#{probe_config[:port]}" if (probe_config[:port].to_i != 443)

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
      petition.ssl_verify_mode = OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT

      # Do the petition
      if (petition.ping)
        # Save the duration
        result.status = HostResult::STATUS_OK
        result.value = petition.duration
      else
        # If the petition ends in error, save the error
        result.status = HostResult::STATUS_ERROR
        result.error = t("probes.https.error.general_error", :err => petition.exception.to_s)
        result.error = t("probes.https.error.connection_refused") if (petition.exception == Errno::ECONNREFUSED)
        result.error = t("probes.https.error.connection_reset") if (petition.exception == Errno::ECONNRESET)
        result.error = t("probes.https.error.redirection_not_followed") if (petition.exception == "Found")
      end

      return result
    end
  end
end