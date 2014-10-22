ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  # fixtures :all

  # Helper to create users in the database to being used in the
  # tests to check privilege levels.
  #
  def create_users
    @user_admin = User.create(:email => "admin@test.tld", :name => "Admin user", :password => "testtest", :password_confirmation => "testtest", :level => User::LEVEL_ADMINISTRATOR)
    @user_normal = User.create(:email => "normal@test.tld", :name => "Normal user", :password => "testtest", :password_confirmation => "testtest", :level => User::LEVEL_NORMAL)
    @user_guest = User.create(:email => "guest@test.tld", :name => "Guest user", :password => "testtest", :password_confirmation => "testtest", :level => User::LEVEL_GUEST)
  end

  # Helper function to destroy all the items in the database
  def clean_db
    Mongoid::Sessions.default.collections.select {|c| c.name !~ /system/}.each {|c| c.find.remove_all}
  end
end
