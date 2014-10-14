class UserMailer < ActionMailer::Base
  default from: Watchr::Application::CONFIG["email"]["default_sender"]
  default template_path: "users/mailer"

  layout "email"
 
  def welcome_email(user)
    @user = user
    mail(to: @user.email, subject: t("users.email.welcome.subject"))
  end

  def change_password_email(user)
    @user = user
    mail(to: @user.email, subject: t("users.email.change_password.subject"))
  end
end
