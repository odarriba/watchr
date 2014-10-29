# This worker sends the e-mails related to Users using
# background functionality provided by Sidekiq
#
class UserMailerWorker
  include Sidekiq::Worker
  
  # Function to send a new e-mail in the background.
  #
  # [Parameters]
  #   * *function* - (Symbol) The function in the UserMailer to call.
  #   * *user_id* - (String) The ID of the user to which send the e-mail.
  #   * *password* - (String) Optional: the new password in case of send a change_password_email
  #
  def perform(function, user_id, password=nil)
    # Load the user
    user = User.find(user_id)
    user.password = password if (!password.blank?)

    # Save the current locale and set the user's one
    @previous_locale = I18n.locale
    I18n.locale = user.lang

    # Welcome e-mail
    UserMailer.welcome_email(user).deliver if (function.to_sym == :welcome_email)
    # Password changed e-mail
    UserMailer.change_password_email(user).deliver if (function.to_sym == :change_password_email)

    # Return to the original locale
    I18n.locale = @previous_locale
  end
end