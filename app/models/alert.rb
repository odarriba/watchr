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
  has_and_belongs_to_many :hosts, :dependent => :nullify

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
end
