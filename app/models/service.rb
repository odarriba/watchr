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
  
  # Highest priority level identificator
  PRIORITY_HIGHEST = 0
  # High priority level identificator
  PRIORITY_HIGH = 1
  # Normal priority level identificator
  PRIORITY_NORMAL = 2
  # Low priority level identificator
  PRIORITY_LOW = 3
  # Lowest priority level identificator
  PRIORITY_LOWEST = 4

  # Available priority levels
  AVAILABLE_PRIORITIES = [PRIORITY_HIGHEST, PRIORITY_HIGH, PRIORITY_NORMAL, PRIORITY_LOW, PRIORITY_LOWEST]

  field :name,            :type => String, :default => ""
  field :probe,           :type => String, :default => ""
  field :probe_config,    :type => Hash, :default => {}
  field :interval,        :type => Integer, :default => 60
  field :clean_interval,  :type => Integer, :default => 604800
  field :priority,        :type => Integer, :default => Service::PRIORITY_NORMAL
  feild :resume,          :type => Symbol, :default => :mean_value

  # Validate fields.
  validates_length_of :name, minimum: 2, maximum: 30
  validates_numericality_of :interval, only_integer: true
  validates_numericality_of :clean_interval, only_integer: true
  validates_inclusion_of :priority, in: Service::AVAILABLE_PRIORITIES
  validates_inclusion_of :resume, in: Service::AVAILABLE_RESUMES

  # Check that the probe field is correct.
  validate :check_probe

  # The fields must be present.
  validates_presence_of :name
  validates_presence_of :probe
  validates_presence_of :probe_config
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
    Watchr::Probes.get_probe(self.probe)
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
end
