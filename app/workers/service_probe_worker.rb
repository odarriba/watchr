# This worker probes the services to the hosts using
# background functionality provided by Sidekiq
#
class ServiceProbeWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :default, :retry => true
  
  # Function to perform a new probe of a service.
  #
  # [Parameters]
  #   * *service* - (String) The ID of the service.
  #
  def perform(service_id)
    # Load the service
    service = Service.where(:_id => service_id).first

    # Service no longer exists? No job then.
    return if (service.blank?)

    p "Executing probe of #{service.name}."

    # Clean previous results
    service.clean_results

    # Only one probe per time
    return if (service.jobs_running > 1)

    # Only do the probe if the service is active.
    return if (!service.is_active?)
    
    # Get the service probe & config
    probe = service.get_probe
    probe_config = service.probe_config

    if (service.hosts.count > 0)
      # Create a new result object
      result = Result.new(:service => service)

      # Execute over every host and save in the results.
      service.hosts.each do |host|
        hresult = probe.execute(host, probe_config)
        result.host_results << hresult if (hresult.is_a?(HostResult))
      end

      # Save the global result
      result.save!
    end

    # Schedule the next test
    service.job_schedule_next

    return true
  end
end