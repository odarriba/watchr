# This worker sends the e-mails related to Alerts using
# background functionality provided by Sidekiq
#
class AlertMailerWorker
  include Sidekiq::Worker
  
  # Function to send a open/closed alert record e-mail in the background.
  #
  # [Parameters]
  #   * *function* - (Symbol) The function in the _AlertMailer_ to call.
  #   * *alert_record_id* - (String) The ID of the _AlertRecord_ which is notified.
  #
  def perform(function, alert_record_id)
    # Load the user
    alert_record = AlertRecord.find(alert_record_id)

    # Save the current locale and set the user's one
    @previous_locale = I18n.locale

    # Send e-mail to each subscribed user
    User.where(:alert_ids => alert_record.alert_id).each do |u|
      I18n.locale = u.lang

      AlertMailer.alert_record_open_email(alert_record, u).deliver if (function.to_sym == :alert_record_open)
      AlertMailer.alert_record_closed_email(alert_record, u).deliver if (function.to_sym == :alert_record_closed)
    end

    # Return to the original locale
    I18n.locale = @previous_locale
  end
end