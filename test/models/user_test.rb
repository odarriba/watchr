require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "should not save user without email" do
    user = User.new(:password => "testtest", :password_confirmation => "testtest", :name => "Test User", :level => User::ADMINISTRATOR_USER, :lang => I18n.default_locale)
    assert_not user.save
  end

  test "should not save user without a valid email" do
    user = User.new(:email => "hey", :password => "testtest", :password_confirmation => "testtest", :name => "Test User", :level => User::ADMINISTRATOR_USER, :lang => I18n.default_locale)
    assert_not user.save
  end

  test "should not save user without name" do
    user = User.new(:email => "hey@test.org", :password => "testtest", :password_confirmation => "testtest", :level => User::ADMINISTRATOR_USER, :lang => I18n.default_locale)
    assert_not user.save
  end
end
