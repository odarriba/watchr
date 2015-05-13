# Alert model to store information about the alerts for the services
# monitored by the application.
#
# Includes fields, definitions and verifications.
#
class Alert
  include Mongoid::Document
  include Mongoid::Timestamps

  CONDITION_TARGET_ALL = :all
  CONDITION_TARGET_ONE = :one

  # Array with the available conditions.
  AVAILABLE_CONDITIONS = [:greater_than, :greater_than_or_equal_to, :equal_to, :less_than_or_equal_to, :less_than]
  # Array with the valid targets.
  AVAILABLE_CONDITION_TARGETS = [CONDITION_TARGET_ALL, CONDITION_TARGET_ONE]

  field :name,              :type => String,  :default => ""
  field :description,       :type => String,  :default => ""
  field :active,            :type => Boolean, :default => true
  field :limit,             :type => Float,   :default => 0.0
  field :condition,         :type => Symbol,  :default => :greater_than
  field :condition_target,  :type => Symbol,  :default => CONDITION_TARGET_ALL
  field :error_control,     :type => Boolean, :default => true

  # Service to monitor
  belongs_to :service, :dependent => :nullify

  # Hosts to monitor
  has_and_belongs_to_many :hosts, :dependent => :nullify, :after_remove => :host_remove

  # Users subscribed
  has_and_belongs_to_many :users, :dependent => :nullify

  # Records of activation of the alert
  has_many :alert_records, :dependent => :destroy

  # Validate fields.
  validates_length_of :name, minimum: 2, maximum: 30
  validates_inclusion_of :condition, in: Alert::AVAILABLE_CONDITIONS
  validates_inclusion_of :condition_target, in: Alert::AVAILABLE_CONDITION_TARGETS

  # Custom validation of hosts
  validate :hosts_linked_to_service?

  # The fields must be present.
  validates_presence_of :name
  validates_presence_of :active
  validates_presence_of :limit
  validates_presence_of :condition
  validates_presence_of :condition_target
  validates_presence_of :error_control
  validates_presence_of :service

  # Function to check if the alert is active.
  #
  # [Returns]
  #   A boolean that indicates if the alert is active.
  #
  def is_active?
    return self.active
  end

  # Function to check if the target of the condition is all the hosts.
  #
  # [Returns]
  #   A boolean that indicates that the target is TARGET_ALL.
  #
  def is_condition_target_all?
    return (self.condition_target == CONDITION_TARGET_ALL)
  end

  # Function to check if the target of the condition is only one host.
  #
  # [Returns]
  #   A boolean that indicates that the target is TARGET_ONE.
  #
  def is_condition_target_one?
    return (self.condition_target == CONDITION_TARGET_ONE)
  end

  def check_activation(result)
    # Check hosts assignation and alert activation
    return if ((self.host_ids.blank?) || (self.is_active? != true))

    # Host actived
    hosts_actived = self.hosts.select{|h| h.is_active?}
    
    # Obtain hosts actived which reuslts matched condition
    hosts_matched = hosts_actived.select{|h| self.condition_matched?(result.get_host_result(h))}

    if (self.is_condition_target_all?)
      # Does the alert match all the actived hosts?
      if (hosts_actived.length == hosts_matched.length)
        ##### Alert opened!!!!!

        # Is there an alert opened?
        alert_record = AlertRecord.where(:alert_id => self.id, :opened => true).first

        # Check if there is an alert record for this
        if (alert_record.blank?)
          # If not, create
          alert_record = AlertRecord.create!(:alert => self, :host_ids => hosts_matched.map{|h| h = h.id}, :opened => true)
        else
          # If yes, update hosts
          alert_record.update_attributes!(:host_ids => hosts_matched.map{|h| h = h.id}, :opened => true)
        end
      else
        ##### Alert not opened!!!

        # Is there any alert opened?
        alert_record = AlertRecord.where(:alert_id => self.id, :opened => true).first
        # Close it if there is one
        alert_record.update_attributes!(:opened => false) if (!alert_record.blank?)
      end
    elsif (self.is_condition_target_one?)
      # Check activation for each host
      self.hosts.each do |h|
        if (hosts_matched.include?(h))
          ##### Alert opened for this host !!!!

          # Check if it is an alert opened for this
          alert_record = AlertRecord.where(:alert_id => self.id, :host_ids => [h.id], :opened => true).first

          # Check if there is an alert record for this
          if (alert_record.blank?)
            # If not, create
            AlertRecord.create!(:alert => self, :host_ids => [h.id], :opened => true)
          else
            # If yes, update hosts
            alert_record.update_attributes!(:host_ids => [h.id], :opened => true)
          end
        else
          ##### Alert no opened for this host !!!!

          # Is there any alert opened?
          alert_record = AlertRecord.where(:alert_id => self.id, :host_ids => h.id, :opened => true).first

          # Close it if there is one
          alert_record.update_attributes!(:opened => false) if (!alert_record.blank?)
        end
      end

      # Close any alert from hosts not registered right now on the alert (but yes in the past)
      AlertRecord.where(:alert_id => self.id, :host_ids.nin => self.host_ids, :opened => true).each do |ar|
        ar.update_attributes!(:opened => false)
      end
    end
  end

  # Function to check if a condition is valid.
  #
  # [Parameters]
  #   * *condition* - The condition to check.
  #
  # [Returns]
  #   A boolean indicating if the condition is valid or not.
  #
  def self.valid_condition?(condition)
    return Alert::AVAILABLE_CONDITIONS.include?(condition)
  end

  # Function to check if a target is valid.
  #
  # [Parameters]
  #   * *target* - The target to check.
  #
  # [Returns]
  #   A boolean indicating if the target is valid or not.
  #
  def self.valid_target?(target)
    return Alert::AVAILABLE_TARGETS.include?(target)
  end

  protected

  def condition_matched?(host_result)
    # Not matched if inactive
    return false if (host_result.status == HostResult::STATUS_INACTIVE)
    # Matched if status is error and error control is activated
    return true if (self.error_control == true && host_result.status == HostResult::STATUS_ERROR)

    # Test value against the limit depending on condition
    case self.condition
    when :greater_than
      return (host_result.value.to_f > self.limit)
    when :greater_than_or_equal_to
      return (host_result.value.to_f >= self.limit)
    when :equal_to
      return (host_result.value.to_f == self.limit)
    when :less_than_or_equal_to
      return (host_result.value.to_f <= self.limit)
    when :less_than
      return (host_result.value.to_f < self.limit)
    else
      return false
    end
  end

  # Function to check if there is any host linked to the alert and not to the service that
  # this alert monitors.
  #
  # [Returns]
  #   A boolean indicating if everything is ok.
  #
  def hosts_linked_to_service?
    if (self.hosts.select{|h| h.service_ids.include?(self.service_id) == false}.count > 0)
      errors.add(:hosts, "hosts must be linked to service");
      return false
    end

    return true
  end

  # Function to close opened alerts when a host is removed from the alert
  # and there is no longer possibility of checking it's host results.
  #
  # [Returns]
  #   A boolean indicating if everything was ok.
  #
  def host_remove(host)
    # If there is any alert opened individually for this host, close it
    if (self.is_condition_target_one?)
      # Is there any alert opened?
      alert_records = AlertRecord.where(:alert_id => self.id, :host_ids => h.id, :opened => true)

      # Close it if there is one
      alert_records.each{|ar| ar.update_attributes!(:opened => false)}
    end

    # If there is no host assigned, close all alerts opened
    if (self.host_ids.blank?)
      alert_records = AlertRecord.where(:alert_id => self.id, :opened => true)

      # Close it if there is one
      alert_records.each{|ar| ar.update_attributes!(:opened => false)}
    end

    return true
  end
end
