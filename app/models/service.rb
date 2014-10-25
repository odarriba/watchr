require 'probes'

# Service model to store information about the services that are
# monitored in the hosts by the application.
#
# Includes fields, probe configuration, definitions and verifications.
#
class Service
  include Mongoid::Document
  include Mongoid::Timestamps

  # Available resume types
  AVAILABLE_RESUMES = [:max_value, :min_value, :mean_value, :sum]

  ####################################################
  # NOTE: The highest priority, the lower the number #
  ####################################################

  # High priority level identificator
  PRIORITY_HIGH = 0
  # Normal priority level identificator
  PRIORITY_NORMAL = 1
  # Low priority level identificator
  PRIORITY_LOW = 2

  # Available priority levels
  AVAILABLE_PRIORITIES = [PRIORITY_HIGH, PRIORITY_NORMAL, PRIORITY_LOW]

  field :name,            :type => String, :default => ""
  field :description,     :type => String, :default => ""
  field :probe,           :type => String, :default => ""
  field :probe_config,    :type => Hash, :default => {}
  field :interval,        :type => Integer, :default => 60
  field :clean_interval,  :type => Integer, :default => 604800
  field :priority,        :type => Integer, :default => Service::PRIORITY_NORMAL
  field :resume,          :type => Symbol, :default => :mean_value

  # Validate fields.
  validates_length_of :name, minimum: 2, maximum: 30
  validates_numericality_of :interval, only_integer: true
  validates_numericality_of :interval, greater_then: 0
  validates_numericality_of :clean_interval, only_integer: true
  validates_numericality_of :clean_interval, greater_then: 0
  validates_inclusion_of :priority, in: Service::AVAILABLE_PRIORITIES
  validates_inclusion_of :resume, in: Service::AVAILABLE_RESUMES

  # Check that the probe field is correct.
  validate :check_probe
  # Check that the probe_config field is correct.
  validate :check_probe_config

  # The fields must be present.
  validates_presence_of :name
  validates_presence_of :probe
  validates_presence_of :interval
  validates_presence_of :clean_interval
  validates_presence_of :priority
  validates_presence_of :resume


  # Function to get the object of the probe associated to this
  # service.
  #
  # [Returns]
  #   A class object of the probe or nil if it fails.
  #
  def get_probe
    return Watchr::Probes.get_probe(self.probe)
  end

  # Function to get an array with the valid probe identificators.
  #
  # [Returns]
  #   An array with the valid probes.
  #
  def self.available_probes
    return Watchr::Probes.available_probes
  end

  # Function to check if a priority level is valid or not.
  #
  # [Parameters]
  #   * *priority* - The priority level to check.
  #
  # [Returns]
  #   A boolean that indicates if the priority is valid or not
  #
  def self.valid_priority?(priority)
    return false if (priority.blank?)

    # Is a valid priority level?
    return Service::AVAILABLE_PRIORITIES.include?(priority)
  end

  # Function to check if a resume type is valid or not.
  #
  # [Parameters]
  #   * *resume_type* - The resume type to check.
  #
  # [Returns]
  #   A boolean that indicates if the resume type is valid or not
  #
  def self.valid_resume?(resume_type)
    return false if (resume_type.blank?)

    # Is a valid resume type?
    return Service::AVAILABLE_RESUMES.include?(resume_type)
  end

  # Function to check if a probe is valid or not.
  #
  # [Parameters]
  #   * *probe* - The probe to check.
  #
  # [Returns]
  #   A boolean that indicates if the probe is valid or not
  #
  def self.valid_probe?(probe)
    return false if (probe.blank?)

    # Is a valid resume type?
    return Watchr::Probes.is_probe?(probe)
  end

  protected

  # Function to check if the _probe_ field is valid.
  #
  # [Returns]
  #   A boolean that indicates if the probe field is valid or not.
  #
  def check_probe
    if (Watchr::Probes.is_probe?(self.probe))
      # Id the probe is valid, return true.
      return true
    else
      # If an error raises, add it to the response
      errors.add(:probe, 'invalid probe')
      return false
    end
  end

  # Function to check if the _probe_config_ field is valid.
  #
  # [Returns]
  #   A boolean that indicates if the probe field is valid or not.
  #
  def check_probe_config
    if (self.get_probe.check_config(self.probe_config))
      # Id the probe is valid, return true.
      return true
    else
      # If an error raises, add it to the response
      errors.add(:probe_config, 'invalid probe config')
      return false
    end
  end
end
