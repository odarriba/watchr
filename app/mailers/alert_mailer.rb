# Mailer class to configure and send _Alert_ related e-mails.
#
class AlertMailer < ActionMailer::Base
  default from: Watchr::Application::CONFIG["email"]["default_sender"]
  default template_path: "alerts/mailer"

  layout "email"

  # Mailer to send the alert record opening e-mail to subscribed users.
  #
  # [Parameters] 
  #   * *alert_record* - The _AlertRecord_ object open.
  #   * *user* - The _User_ to which send the email
  #
  def alert_record_open_email(alert_record, user)
    @alert_record = alert_record
    @user = user
    
    mail(to: @user.email, subject: t("alerts.email.alert_record_open.subject", :alert => @alert_record.alert.name))
  end

  # Mailer to send the alert record closing e-mail to subscribed users.
  #
  # [Parameters] 
  #   * *alert_record* - The _AlertRecord_ object closed.
  #   * *user* - The _User_ to which send the email
  #
  def alert_record_closed_email(alert_record, user)
    @alert_record = alert_record
    @user = user
    
    mail(to: @user.email, subject: t("alerts.email.alert_record_closed.subject", :alert => @alert_record.alert.name))
  end
end
