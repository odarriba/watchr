module Watchr
  class Probes
    # Probe information hash
    PROBES = {}

    # This class function provides auto-discovery and loading
    # of the probes in /lib/probes using the defined tree structure.
    #
    def self.load_probes
      path = File.join(Rails.root, 'lib', 'probes')

      Dir.entries(path).each do |probe| 
        path_probe = File.join(path,probe)
        # Check that is a real directory and that the .rb inside ir exists.
        if (probe != "." && probe != ".." && File.directory?(path_probe) && File.exists?(File.join(path_probe, "#{probe}.rb")))
          require File.join(path_probe, "#{probe}.rb")
        end
      end

      return
    end

    # This function is used to register a probe in the variables of
    # defined probes to allow them to be used within the application.
    #
    # [Parameters]
    #   * *name* - The name of the probe
    #   * *klass* - The class object of the probe.
    #
    # [Returns]
    #   A boolean that indicates if the probe was added or not.
    #
    def self.register_probe(klass)
      # Invalid parameters?
      return false if (klass.blank? || !klass.is_a?(Class))
      return false if (klass.name.blank?)

      # Save the probe.
      PROBES[klass.name] = klass
      return true
    end

    # Function to get an array of the available probes registered.
    #
    # [Returns]
    #   An array with the identificators of the probes.
    #
    def self.available_probes
      return PROBES.keys
    end

    # Function to get a hash with the information of all the registered probes.
    #
    # [Returns]
    #   A hash with the information of all the registered probes.
    #
    def self.probes_information
      result = Hash.new

      PROBES.each do |name, klass|
        probe = {:name => name, :description => klass.get_description, :probe => klass}
        result[name] = probe
      end

      return result
    end

    # Function to validate a probe identificator.
    #
    # [Parameters]
    #   * *probe_name* - Name of the probe to check.
    #
    # [Returns]
    #   A boolean that indicates if the probe name is valid or not.
    #
    def self.is_probe?(probe_name)
      return Watchr::Probes.available_probes.include?(probe_name)
    end

    # Function to get the class object to operate with a probe.
    #
    # [Parameters]
    #   * *probe_name* - The probe of the name to obtain
    #
    # [Returns]
    #   A class object of the probe or nil if it doesn't exists.
    #
    def self.get_probe(probe_name)
      return nil if (probe_name.blank?)

      return PROBES[probe_name]
    end
  end
end