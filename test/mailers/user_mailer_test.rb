require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  def setup
    # MongoID hasn't got fixtures support :(
    @user = User.new(:email => "hey@test.org", :password => "testtest", :password_confirmation => "testtest", :name => "Test User", :level => User::LEVEL_ADMINISTRATOR, :lang => I18n.default_locale)
  end

  def teardown
    User.destroy_all
  end

  test "should send a valid welcome email" do
    UserMailer.welcome_email(@user).deliver

    mail = ActionMailer::Base.deliveries.last

    assert_equal Watchr::Application::CONFIG["email"]["default_sender"], mail['from'].to_s
    assert_equal @user.email, mail['to'].to_s
    assert_equal I18n.t("users.email.welcome.subject"), mail['subject'].to_s
  end

  test "should send a valid password change email" do
    UserMailer.change_password_email(@user).deliver

    mail = ActionMailer::Base.deliveries.last

    assert_equal Watchr::Application::CONFIG["email"]["default_sender"], mail['from'].to_s
    assert_equal @user.email, mail['to'].to_s
    assert_equal I18n.t("users.email.change_password.subject"), mail['subject'].to_s
  end
end
