module Watchr
  class Probes
    AVAILABLE_PROBES = []
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
    def self.register_probe(name, klass)
      PROBES[name] = klass
      AVAILABLE_PROBES << name
    end
  end
end