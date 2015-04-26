require 'probes/probe'
require 'net/ping/tcp'

module Watchr
  # This is a TCP connectivity test using the port defined by the service.
  #
  # Use it to test the status of a TCP port in the remote host
  #
  class TcpConnectionProbe < Watchr::Probe
    # Probe name
    PROBE_NAME = "tcp_connection"
    # Probe description
    PROBE_DESCRIPTION = "It checks the ability to perform a TCP connection to a port of the remote host."
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
      return t("probes.tcp_connection.description") if (t("probes.tcp_connection.description"))
      super
    end

    # Function to get the HTML description of the probe
    #
    # [Returns]
    #   A string with the HTML description of the probe
    #
    def self.description_html
      return t("probes.tcp_connection.description_html") if (t("probes.tcp_connection.description_html"))
      super
    end

    # Function to get the units in which are expresed the results
    #
    # [Returns]
    #   A string with the units of the results
    #
    def self.results_units
      return t("probes.tcp_connection.results_units") if (t("probes.tcp_connection.results_units"))
      super
    end

    # Function to get the short name of the units in which are expresed 
    # the results
    #
    # [Returns]
    #   A string with the units of the results
    #
    def self.results_units_short
      return t("probes.tcp_connection.results_units_short") if (t("probes.tcp_connection.results_units_short"))
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
      return ((!config[:port].blank?) && (config[:port].to_i >= 1) && (config[:port].to_i <= 65535))
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
        result.error = t("probes.tcp_connection.error.config_invalid")

        return result
      end

      # Create the connection object
      conn = Net::Ping::TCP.new(host.address, probe_config[:port])

      if (conn.ping(host.address))
        # Save the duration
        result.status = HostResult::STATUS_OK
        result.value = conn.duration*1000
      else
        # If the connection ends in error, save the error
        result.status = HostResult::STATUS_ERROR
        result.error = t("probes.tcp_connection.error.general_error", :err => conn.exception.to_s)
        result.error = t("probes.tcp_connection.error.connection_refused") if (conn.exception == Errno::ECONNREFUSED)
        result.error = t("probes.tcp_connection.error.connection_reset") if (conn.exception == Errno::ECONNRESET)
      end

      return result
    end
  end
end