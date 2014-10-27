# Helper functions for _ServicesController_ actions.
#
module ServicesHelper
  # Helper function to get a hash with the valid priorities of _Service_ model.
  #
  # [Returns]
  #   Hash with the priority identificators associated to the translations of the priority names.
  #
  def service_priorities_hash
    result = Hash.new

    Service::AVAILABLE_PRIORITIES.each do |prior|
      result[t("services.priorities.priority_#{prior.to_s}")] = prior
    end

    return result
  end

  # Helper function to get a hash with the valid probes loaded for _Service_ model.
  #
  # [Returns]
  #   Hash with the probe identificators of the probes.
  #
  def service_probes_hash
    result = Hash.new

    Service.available_probes.each do |probe|
      result[probe] = probe
    end

    return result
  end

  # Helper function to get a hash with the valid resumes of _Service_ model.
  #
  # [Returns]
  #   Hash with the resume identificators associated to the translations of the resume names.
  #
  def service_resumes_hash
    result = Hash.new

    Service::AVAILABLE_RESUMES.each do |resume|
      result[t("services.resumes.resume_#{resume.to_s}")] = resume.to_s
    end

    return result
  end
end
