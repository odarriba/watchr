class Result
  include Mongoid::Document
  include Mongoid::Timestamps

  # Belongs to a service
  belongs_to :service, :dependent => :nullify

  # Embeds many host results (one for every host associated to the service)
  embeds_many :host_results, :as => true, :cascade_callbacks => true

  validates_presence_of :service

  # Function to get the _HostResult_ object of a determined host
  #
  # [Parameters]
  #   * *host* - The Host objecto or the id of a Host object.
  #
  # [Returns]
  #   The _HostResult_ object.
  #
  def get_host_result(host)
    host = host.id if (host.is_a?(Host))
    return self.host_services.select{|u| u.host_id = host}.first
  end

  # Function to get the global value of the results done to the hosts.
  #
  # [Returns]
  #   The float with the global value
  #
  def global_value
    return 0.0 if (self.all_error?)

    results = []

    # Get the result values
    self.host_results.each do |result|
      results << result.value if (result.is_valid?)
    end

    # Return the value
    return self.service.resume_values(results)
  end

  # Function to know if there is an error in all the probes done
  # to the hosts.
  #
  # [Returns]
  #   A boolean that indicates if there is a global error or not.
  #
  def all_error?
    return self.host_results.select{|h| !h.error?}.blank?
  end

  # Function to know if there is an error in any of the hosts monitored
  # by the service.
  #
  # [Returns]
  #   A boolean that indicates if there is any error in the host results or not.
  #
  def any_error?
    return (!self.host_results.index{|h| h.error?}.blank?)
  end

  # Function to know if all the probes done to the host were valid or not.
  #
  # [Returns]
  #   A boolean that indicates if all the results are valid or not.
  #
  def all_valid?
    return self.host_results.select{|h| !h.valid?}.blank?
  end

  # Function to know if there is any valid probe done to the hosts monitored
  # by the service.
  #
  # [Returns]
  #   A boolean that indicates if there is any valid result or not.
  #
  def any_valid?
    return (!self.host_results.index{|h| h.valid?}.blank?)
  end

  # Function to get the timestamp of the result.
  #
  # [Returns]
  #   A Time object with the timestamp of the result.
  #
  def timestamp
    return self.created_at
  end
end
