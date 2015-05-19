require 'test_helper'

class PanelControllerTest < ActionController::TestCase
  include Devise::TestHelpers
  
  def setup
    @user = User.create(:email => "admin@test.tld", :name => "Admin user", :password => "testtest", :password_confirmation => "testtest", :level => User::LEVEL_ADMINISTRATOR)
  end

  def teardown
    @user.destroy
  end

  test "should not get index if not signed in" do
    get :index
    assert_redirected_to new_user_session_path

    xhr :get, :index
    assert_redirected_to new_user_session_path
  end

  test "should get index if signed in" do
    sign_in :user, @user

    get :index
    assert_response :success
    assert_template :layout => :application
    assert_template :index

    xhr :get, :index
    assert_response :success
    assert_template :index
  end

end
