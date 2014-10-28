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

  # Helper function to create a host in the DB
  #
  # [Parameters]
  #   * *data* - The data to create a host
  #
  def create_host(data=nil)
    if (!data.blank? && data.is_a?(Hash))
      @host = Host.create(data)
    else
      @host = Host.create(:name => "Test Host", :type => Host::TYPE_ROUTER, :address => "google.com", :description => "Test host description.", :active => true)
    end
  end

  # Helper function to create a service in the DB
  #
  # [Parameters]
  #   * *data* - The data to create a service
  #
  def create_service(data=nil)
    if (!data.blank? && data.is_a?(Hash))
      @service = Service.create(data)
    else
      @service = Service.create(:name => "Test Service", :description => "Test service description.", :active => true, :probe => "dummy", :probe_config => {:value => 1}, :interval => 60, :clean_interval => 86400, :priority => Service::PRIORITY_NORMAL, :resume => :mean_value)
    end
  end

  # Helper function to destroy all the items in the database
  #
  def clean_db
    Mongoid::Sessions.default.collections.select {|c| c.name !~ /system/}.each {|c| c.find.remove_all}
  end
end
