# Alert model to store information about the alerts for the services
# monitored by the application.
#
# Includes fields, definitions and verifications.
#
class Alert
  include Mongoid::Document
  include Mongoid::Timestamps

  # Array with the available conditions.
  AVAILABLE_CONDITIONS = [:greater_than, :greater_than_or_equal_to, :equal_to, :less_than_or_equal_to, :less_than]
  # Array with the valid targets.
  AVAILABLE_TARGETS = [:service, :host]

  field :name,        :type => String, :default => ""
  field :description, :type => String, :default => ""
  field :active,      :type => Boolean, :default => true
  field :limit,       :type => Float, :default => 0.0
  field :condition,   :type => Symbol, :default => :greater_than
  field :target,      :type => Symbol, :default => :service

  # Service to monitor
  belongs_to :service, :dependent => :nullify

  # Validate fields.
  validates_length_of :name, minimum: 2, maximum: 30
  validates_inclusion_of :condition, in: Alert::AVAILABLE_CONDITIONS
  validates_inclusion_of :target, in: Alert::AVAILABLE_TARGETS

  # The fields must be present.
  validates_presence_of :name
  validates_presence_of :limit
  validates_presence_of :condition
  validates_presence_of :target
  validates_presence_of :service

  # Function to check if the alert is active.
  #
  # [Returns]
  #   A boolean that indicates if the alert is active.
  #
  def is_active?
    return self.active
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
    return Alert::AVAILABLE_CONDITIONS.inlcude?(condition)
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
    return Alert::AVAILABLE_TARGETS.inlcude?(target)
  end
end
