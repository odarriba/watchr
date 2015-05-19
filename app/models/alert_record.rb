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

  # Callbacks
  after_create :creation_actions
  before_update :check_email_sends

  protected

  # Callback function to send opening email in case the created _AlertRecord_
  # is in OPENED status and the users subscribed has to be notified.
  #
  # [Returns]
  #   Nothing.
  #
  def creation_actions
    if (self.opened)
      # AlertRecord has been opened
      AlertMailerWorker.perform_async(:alert_record_opened, self.id.to_s)
    end
  end

  # Callback function to send opening/closing email in case the created 
  # _AlertRecord_ has changed it's status and the users subscribed has to 
  # be notified.
  #
  # [Returns]
  #   Nothing.
  #
  def check_email_sends
    if (self.opened_changed?)
      if ((self.opened_was == true) && (self.opened == false))
        # AlertRecord has been closed
        AlertMailerWorker.perform_async(:alert_record_closed, self.id.to_s)
      elsif ((self.opened_was == false) && (self.opened == true))
        # AlertRecord has been opened
        AlertMailerWorker.perform_async(:alert_record_opened, self.id.to_s)
      end
    end
  end
end
