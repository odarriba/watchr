require 'probes'
require 'sidekiq/api'

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
  field :active,          :type => Boolean, :default => true
  field :probe,           :type => String, :default => ""
  field :probe_config,    :type => Hash, :default => {}
  field :interval,        :type => Integer, :default => 60
  field :clean_interval,  :type => Integer, :default => 604800
  field :priority,        :type => Integer, :default => Service::PRIORITY_NORMAL
  field :resume,          :type => Symbol, :default => :mean_value

  # Has assigned hosts to test the service
  has_and_belongs_to_many :hosts, :dependent => :nullify

  # Has results of testing the service over the hosts
  has_many :results, :dependent => :destroy

  # Has alerts that monitor the results of the service
  has_many :alerts, :dependent => :nullify

  # Validate fields.
  validates_length_of :name, minimum: 2, maximum: 30
  validates_numericality_of :interval, only_integer: true
  validates_numericality_of :interval, greater_than: 0
  validates_numericality_of :clean_interval, only_integer: true
  validates_numericality_of :clean_interval, greater_than: 0
  validates_inclusion_of :priority, in: Service::AVAILABLE_PRIORITIES
  validates_inclusion_of :resume, in: Service::AVAILABLE_RESUMES

  # Check that the probe field is correct.
  validate :check_probe
  # Check that the probe_config field is correct.
  validate :check_probe_config

  # The fields must be present.
  validates_presence_of :name
  validates_presence_of :active
  validates_presence_of :probe
  validates_presence_of :interval
  validates_presence_of :clean_interval
  validates_presence_of :priority
  validates_presence_of :resume

  after_save :manage_job
  after_create :manage_job
  before_destroy :job_stop


  # Function to get the object of the probe associated to this
  # service.
  #
  # [Returns]
  #   A class object of the probe or nil if it fails.
  #
  def get_probe
    return Watchr::Probes.get_probe(self.probe)
  end

  # Function to check if the service is active.
  #
  # [Returns]
  #   A boolean that indicates if the service is active.
  #
  def is_active?
    return self.active
  end

  # Function do the resume function over an array of results.
  #
  # [Parameters]
  #   * *values* - An array with float values.
  #
  # [Returns]
  #   The resume value.
  #
  def resume_values(values)
    if (self.resume == :max_value)
      return values.max
    elsif (self.resume == :min_value)
      return values.min
    elsif (self.resume == :mean_value)
      return values.reduce(:+).to_f / values.size
    elsif (self.resume == :sum)
      return values.inject(:+)
    else
      return nil
    end
  end

  # Function to start a job that wasn't running or waiting
  #
  # [Returns]
  #   A boolean that indicates if the job has been started or not.
  #
  def job_start
    # Only start if it isn't running
    if (self.jobs_running == 0)
      # Try to add ir to the schedule
      return self.job_schedule_next
    else
      return false # If it's already running
    end
  end

  # Function to stop a probe job from being executed.
  #
  # It allows to remove all the waiting jobs (scheduled and queued).
  #
  def job_stop
    scheduled_jobs = Sidekiq::ScheduledSet.new
    queue_jobs = Sidekiq::Queue.new
    retry_jobs = Sidekiq::RetrySet.new

    # Delete from the scheduled jobs
    scheduled_jobs.select{|job| (job.klass=="ServiceProbeWorker" && job.args.include?(self.id.to_s))}.each do |job|
      job.delete
    end
    
    # Delete from the queue
    queue_jobs.select{|job| (job.klass=="ServiceProbeWorker" && job.args.include?(self.id.to_s))}.each do |job|
      job.delete
    end

    # Delete from the retry list
    retry_jobs.select{|job| (job.klass=="ServiceProbeWorker" && job.args.include?(self.id.to_s))}.each do |job|
      job.delete
    end
  end

  # Function to schedule a new background job to perform the probe test
  # assigned to this service to the hosts.
  #
  # [Returns]
  #   A boolean that indicates if the scheduling was done right or not.
  #
  def job_schedule_next
    # Check there isn't another job of this probe scheduled or waiting.
    if (self.jobs_waiting == 0)
      return true if (ServiceProbeWorker.perform_in(self.interval, self.id.to_s))
      return false # It fails
    else
      return false # It's already scheduled one.
    end
  end

  # Function to get the number of jobs scheduled or waitingto be executed
  # to test this service.
  #
  # [Returns]
  #   The number of jobs of this service waiting to be scheduled or executed.
  #
  def jobs_waiting
    scheduled_jobs = Sidekiq::ScheduledSet.new
    queue_jobs = Sidekiq::Queue.new
    retry_jobs = Sidekiq::RetrySet.new

    # It's an scheduled job?
    njobs = scheduled_jobs.select{|job| (job.klass=="ServiceProbeWorker" && job.args.include?(self.id.to_s))}.count
    
    # It's an queued job?
    njobs += queue_jobs.select{|job| (job.klass=="ServiceProbeWorker" && job.args.include?(self.id.to_s))}.count
    return njobs if (njobs > 0)

    # It's an retried job?
    njobs += retry_jobs.select{|job| (job.klass=="ServiceProbeWorker" && job.args.include?(self.id.to_s))}.count
    return njobs if (njobs > 0)

    # Return the result
    return njobs
  end

  # Function to get the number of service jobs being executed for 
  # this particular service.
  #
  # [Returns]
  #   The number of service jobs being executed.
  #
  def jobs_running
    workers = Sidekiq::Workers.new

    # It's running?
    njobs = workers.select{|process_id, thread_id, work| (work["payload"]["class"] == "ServiceProbeWorker" && work["payload"]["args"].include?(self.id.to_s))}.count

    # Return the result
    return njobs
  end

  # Function to manage the start/stop of the job depending of the
  # activation status
  #
  # [Returns]
  #   The return value of _job_start_ or _job_stop_ functions.
  #
  def manage_job
    return self.job_start if (self.active == true)
    return self.job_stop if (self.active == false)
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
    return false if (!Service.valid_probe?(self.probe))

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
