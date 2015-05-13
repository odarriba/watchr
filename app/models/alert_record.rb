# Alert Record model to store information about the alert activations for the services
# monitored by the application.
#
# Includes fields, definitions and verifications.
#
class AlertRecord
  include Mongoid::Document
  include Mongoid::Timestamps

  field :opened, 	:type => Boolean, 	:default => true

  # Hosts affected
  has_and_belongs_to_many :hosts, :inverse_of => nil
  
  # Service affected
  belongs_to :service, :inverse_of => nil

  # Belongs to an alert
  belongs_to :alert, :dependent => :nullify

  validates_presence_of :opened
  validates_presence_of :hosts
  validates_presence_of :alert
end
