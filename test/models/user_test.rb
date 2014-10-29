require 'test_helper'

class UserTest < ActiveSupport::TestCase

  def setup
    # MongoID hasn't got fixtures support :(
    @user = User.new(:email => "hey@test.org", :password => "testtest", :password_confirmation => "testtest", :name => "Test User", :level => User::LEVEL_ADMINISTRATOR, :lang => I18n.default_locale)
  end

  def teardown
    User.destroy_all
  end

  test "should not save user without a valid email" do
    # no E-mail
    @user.email = ""
    assert_not @user.save
    assert_not @user.errors[:email].blank?

    # No domain
    @user.email = "hey"
    assert_not @user.save
    assert_not @user.errors[:email].blank?

    # No TLD
    @user.email = "hey@test"
    assert_not @user.save
    assert_not @user.errors[:email].blank?

    # No username
    @user.email = "test.org"
    assert_not @user.save
    assert_not @user.errors[:email].blank?
  end

  test "should save user with an empty gravatar email" do
    @user.gravatar_email = ""
    assert @user.save
  end

  test "should copy the email in gravatar email if empty" do
    @user.gravatar_email = ""
    @user.save

    assert_equal @user.email, @user.gravatar_email
  end

  test "should save downcased emails" do
    original_email = "Hey@TesT.orG"

    @user.email = original_email
    @user.gravatar_email = original_email
    @user.save

    assert_equal @user.email, original_email.downcase
    assert_equal @user.gravatar_email, original_email.downcase
  end

  test "a welcome email should be sended" do
    count_pre = UserMailerWorker.jobs.count

    @user.save

    count_post = UserMailerWorker.jobs.count

    assert_equal count_pre+1, count_post
  end 

  test "should not save user without a valid password" do
    # Empty password
    @user.password = ""
    @user.password_confirmation = ""
    assert_not @user.save
    assert_not @user.errors[:password].blank?

    # Different password
    @user.password = "testtest"
    @user.password_confirmation = "texttext"
    assert_not @user.save
    assert_not @user.errors[:password_confirmation].blank?

    # Short password
    @user.password = "test"
    @user.password_confirmation = "test"
    assert_not @user.save
    assert_not @user.errors[:password].blank?
  end

  test "should not save user without a valid name" do
    # Empty name
    @user.name = ""
    assert_not @user.save
    assert_not @user.errors[:name].blank?

    # Short name
    @user.name = "a"
    assert_not @user.save
    assert_not @user.errors[:name].blank?

    # Long name
    @user.name = "qwertyuiopasdfghjklñzxcvbnmqwertyuiop"
    assert_not @user.save
    assert_not @user.errors[:name].blank?
  end

  test "should not save user without a valid level" do
    # Empty string
    @user.level = ""
    assert_not @user.save
    assert_not @user.errors[:level].blank?

    # String with negative number
    @user.level = "-1"
    assert_not @user.save
    assert_not @user.errors[:level].blank?

    # Invalid level
    @user.level = 69
    assert_not @user.save
    assert_not @user.errors[:level].blank?

    # Invalid level
    @user.level = -1
    assert_not @user.save
    assert_not @user.errors[:level].blank?

    # Invalid level
    @user.level = :ADMINISTRATOR
    assert_not @user.save
    assert_not @user.errors[:level].blank?

    # Nil level
    @user.level = nil
    assert_not @user.save
    assert_not @user.errors[:level].blank?
  end

  test "should save user with valid levels" do
    # Administrator level
    @user.level = User::LEVEL_ADMINISTRATOR
    assert @user.save

    # Normal level
    @user.level = User::LEVEL_NORMAL
    assert @user.save

    # Guest level
    @user.level = User::LEVEL_GUEST
    assert @user.save
  end

  test "should should recognise it's user privilege level" do
    # Administrator level
    @user.level = User::LEVEL_ADMINISTRATOR
    assert @user.is_administrator?
    assert @user.is_normal?
    assert @user.is_guest?

    # Normal level
    @user.level = User::LEVEL_NORMAL
    assert_not @user.is_administrator?
    assert @user.is_normal?
    assert @user.is_guest?

    # Guest level
    @user.level = User::LEVEL_GUEST
    assert_not @user.is_administrator?
    assert_not @user.is_normal?
    assert @user.is_guest?
  end

  test "should recognise an valid level" do
    # Administrator level
    assert User::valid_level?(User::LEVEL_ADMINISTRATOR)

    # Normal level
    assert User::valid_level?(User::LEVEL_NORMAL)

    # Guest level
    assert User::valid_level?(User::LEVEL_GUEST)
  end

  test "should recognise an invalid level" do
    # Empty string
    assert_not User::valid_level?("")

    # String with negative number
    assert_not User::valid_level?("-1")

    # Invalid level
    assert_not User::valid_level?(69)

    # Invalid level
    assert_not User::valid_level?(-1)

    # Invalid level
    assert_not User::valid_level?(:ADMINISTRATOR)

    # Nil level
    assert_not User::valid_level?(nil)
  end

  test "should not save user without a valid language" do
    # Empty string
    @user.lang = ""
    assert_not @user.save
    assert_not @user.errors[:lang].blank?

    # String with unknown lang
    @user.lang = "drft"
    assert_not @user.save
    assert_not @user.errors[:lang].blank?

    # Unknown lang
    @user.lang = :drft
    assert_not @user.save
    assert_not @user.errors[:lang].blank?

    # Number in string
    @user.lang = "0"
    assert_not @user.save
    assert_not @user.errors[:lang].blank?

    # Number
    @user.lang = 0
    assert_not @user.save
    assert_not @user.errors[:lang].blank?
  end

  test "should save a valid user" do
    assert @user.save
  end

  test "should not save a existing user" do
    assert @user.save

    setup

    assert_not @user.save
  end
end
