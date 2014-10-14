class UserMailer < ActionMailer::Base
  default from: Watchr::Application::CONFIG["email"]["default_sender"]
  default template_path: "users/mailer"

  layout "email"

  # Mailer to send the welcome email to an user with it's login details.
  #
  # [user] The user object to wich one send the e-mail
  #
  def welcome_email(user)
    @user = user
    mail(to: @user.email, subject: t("users.email.welcome.subject"))
  end

  # Mailer to send the ans email to an user warning about an password change.
  #
  # [user] The user object to wich one send the e-mail
  #
  def change_password_email(user)
    @user = user
    mail(to: @user.email, subject: t("users.email.change_password.subject"))
  end
end
