# Result model to store information about global results fetched
# from the realization of a probe assigned to a service.
#
# Includes relations, fields, auxiliar functions and verifications.
#
class Result
  include Mongoid::Document
  include Mongoid::Timestamps

  # Belongs to a service
  belongs_to :service, :dependent => :nullify

  # Embeds many host results (one for every host associated to the service)
  embeds_many :host_results, :as => true, :cascade_callbacks => true

  after_create :check_alerts

  validates_presence_of :service
  validate :has_host_results
  validate :check_host_results
  validate :only_one_host_per_result

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
    return self.host_results.select{|u| u.host_id == host}.first
  end

  # Function to get the value associated to the host
  #
  # [Parameters]
  #   * *host* - The Host objecto or the id of a Host object.
  #
  # [Returns]
  #   The _HostResult_ object.
  #
  def get_host_value(host)
    host = host.id if (host.is_a?(Host))
    return self.get_host_result(host).value.to_i.round(4)
  end

  # Function to get the resumed value of the results done to the hosts.
  #
  # *Note:* this function should not be used in batch functions because
  # it causes high DB usage loading the service every time.
  #
  # [Parameters]
  #   * *resume* - The resume type to use (from Service::AVAILABLE_RESUMES). 
  #                If it isn't passed or not valid, service's default is used.
  #
  # [Returns]
  #   The float with the global value rounded to 4 digits.
  #
  def global_value(resume = nil)
    return 0.0 if (self.all_error?)

    # Put the resume to it's default value if it isn't recognised
    resume = self.service.resume if (!Service::AVAILABLE_RESUMES.include?(resume))

    # Return the value
    return self.service.resume_values(self.get_values, resume).round(4)
  end

  # Function to get an array with all the values of the results from the 
  # probes done to the hosts.
  #
  # [Returns]
  #   An array with all the results
  #
  def get_values
    return [0.0] if (!self.any_ok?)

    results = []

    # Get the result values
    self.host_results.each do |result|
      results << result.value if (result.is_ok?)
    end

    # Return the value
    return results
  end

  # Function to know if there is an error in all the probes done
  # to the hosts.
  #
  # [Returns]
  #   A boolean that indicates if there is a global error or not.
  #
  def all_error?
    return self.host_results.select{|h| !h.is_error?}.blank?
  end

  # Function to know if there is an error in any of the hosts monitored
  # by the service.
  #
  # [Returns]
  #   A boolean that indicates if there is any error in the host results or not.
  #
  def any_error?
    return (!self.host_results.index{|h| h.is_error?}.blank?)
  end

  # Function to know if all the probes done to the host were valid or not.
  #
  # [Returns]
  #   A boolean that indicates if all the results are valid or not.
  #
  def all_ok?
    return self.host_results.select{|h| !h.is_ok?}.blank?
  end

  # Function to know if there is any valid probe done to the hosts monitored
  # by the service.
  #
  # [Returns]
  #   A boolean that indicates if there is any valid result or not.
  #
  def any_ok?
    return (!self.host_results.index{|h| h.is_ok?}.blank?)
  end

  # Function to get the timestamp of the result.
  #
  # [Returns]
  #   A Time object with the timestamp of the result.
  #
  def timestamp
    return self.created_at
  end

  protected

  # Function to check if there is at least one host result embedded in
  # this result before saving (in validation time).
  #
  # [Returns]
  #   A boolean that indicates if the validation was passed or not.
  #
  def has_host_results
    if (self.host_results.empty?)
      errors.add(:host_results, 'cannot be empty')
      return false
    end

    return true
  end

  # Function to check if the host of every HostResult is assigned to the
  # serviceof this Result object.
  #
  # [Returns]
  #   A boolean indicating if everything is ok.
  #
  def check_host_results
    self.host_results.each do |hresult|
      if (!self.service.host_ids.include?(hresult.host_id))
        errors.add(:host_results, 'has a host_result with an unlinked host')
        return false
      end
    end

    return true
  end

  def check_alerts
    alerts = Alert.where(:service_id => self.service_id)

    alerts.each do |alert|
      alert.check_activation(self)
    end
  end

  # Function to check if there is a host with more than one HostResult 
  # assigned to this Result object.
  #
  # [Returns]
  #   A boolean indicating if everything is ok.
  #
  def only_one_host_per_result
    self.host_results.each do |hresult|
      if (self.host_results.select{|hres| hres.host_id == hresult.host_id}.count > 1)
        errors.add(:host_results, 'has a host_result with a duplicated host')
        return false
      end
    end

    return true
  end
end
