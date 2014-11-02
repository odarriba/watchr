require 'probes/probe'
require 'net/ping/udp'

module Watchr
  # This is a UDP ping connectivity test using the port defined by the service.
  #
  # Use it to test the connectivity to a remote host using UDP. It sends a message
  # to an UDP port and wait for a response with the same message.
  #
  class PingUdpProbe < Watchr::Probe
    # Probe name
    PROBE_NAME = "ping_udp"
    # Probe description
    PROBE_DESCRIPTION = "It pings a remote host sending a message to an UDP port and waiting for the same message in response."

    # Register this probe
    self.register_this

    # Function to get the description of the probe
    #
    # [Returns]
    #   A string with the description of the probe
    #
    def self.description
      return t("probes.ping_udp.description") if (t("probes.ping_udp.description"))
      super
    end

    # Function to get the HTML description of the probe
    #
    # [Returns]
    #   A string with the HTML description of the probe
    #
    def self.description_html
      return t("probes.ping_udp.description_html") if (t("probes.ping_udp.description_html"))
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
        result.error = t("probes.ping_udp.error.config_invalid")

        return result
      end

      # Create the ping object
      ping = Net::Ping::UDP.new(host.address, probe_config[:port])

      if (ping.ping(host.address))
        # Save the duration
        result.status = HostResult::STATUS_OK
        result.value = ping.duration
      else
        # If the ping ends in error, save the error
        result.status = HostResult::STATUS_ERROR
        result.error = t("probes.ping_udp.error.general_error", :err => ping.exception.to_s)
        result.error = t("probes.ping_udp.error.connection_refused") if (ping.exception == Errno::ECONNREFUSED)
        result.error = t("probes.ping_udp.error.connection_reset") if (ping.exception == Errno::ECONNRESET)
      end

      return result
    end
  end
end