require 'test_helper'

class InstallationControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def setup
    User.destroy_all
  end

  def teardown
    User.destroy_all
  end

  test "should get start" do
    get :start

    # Check response and template used
    assert_response :success
    assert_template :layout => :devise
    assert_template :start
  end

  test "should not get start with an administrator" do
    @user = User.create(:email => "admin@test.tld", :name => "Admin user", :password => "testtest", :password_confirmation => "testtest", :level => User::ADMINISTRATOR_USER)

    get :start

    # As exists an administrator, the user must be redirected
    assert_redirected_to root_path
  end

  test "should get start with a non-administrator user" do
    # Create a normal user
    @user = User.create(:email => "normal@test.tld", :name => "Normal user", :password => "testtest", :password_confirmation => "testtest", :level => User::NORMAL_USER)

    get :start

    # Check response and template used
    assert_response :success
    assert_template :layout => :devise
    assert_template :start

    # Destroy previous user
    @user.destroy

    # Create a guest user
    @user = User.create(:email => "guest@test.tld", :name => "Guest user", :password => "testtest", :password_confirmation => "testtest", :level => User::GUEST_USER)

    get :start

    # Check response and template used
    assert_response :success
    assert_template :layout => :devise
    assert_template :start
  end

  test "should finish installation" do
    user_data = {:name => 'Administrator', :email => "admin@test.tld"}
    post :apply, :user => user_data

    assert User.where(:email => "admin@test.tld", :level => User::ADMINISTRATOR_USER)
    assert_redirected_to new_user_session_path
    assert_equal User.count, 1

    @user = User.all.first

    assert_equal @user.email, user_data[:email].downcase
    assert_equal @user.name, user_data[:name]
    assert_equal @user.level, User::ADMINISTRATOR_USER
  end

  test "should not finish installation without valid data" do
    user_data = {:name => 'a', :email => "admin@test.tld"}
    post :apply, :user => user_data

    # Check that the user is returned to the form
    assert_template :layout => :devise
    assert_template :start

    # Check that user isn't saved
    assert_equal User.count, 0

    user_data = {:name => 'Administrator', :email => "admin"}
    post :apply, :user => user_data

    # Check that the user is returned to the form
    assert_template :layout => :devise
    assert_template :start

    # Check that user isn't saved
    assert_equal User.count, 0
  end

  test "should drop every user when installation finish" do
    # Create normal user
    @user = User.create(:email => "normal@test.tld", :name => "Normal user", :password => "testtest", :password_confirmation => "testtest", :level => User::NORMAL_USER)

    user_data = {:name => 'Administrator', :email => "admin@test.tld"}
    post :apply, :user => user_data

    assert_redirected_to new_user_session_path

    assert_not User.where(:email => "normal@test.tld").first
    assert_not User.ne(:level => User::ADMINISTRATOR_USER).first
  end

end
