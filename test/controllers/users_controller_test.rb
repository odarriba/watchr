require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def setup
    # Create test users
    create_users

    @create_hash = {:email => "test@test.tld", :name => "Test user", :password => "testtest", :password_confirmation => "testtest", :level => User::LEVEL_NORMAL}
  end

  def teardown
    clean_db
  end

  test "crud operations should not be accesible for guests" do
    sign_in :user, @user_guest

    # Can't index users
    get :index
    assert_redirected_to root_path

    # Can't view users
    get :show, :id => @user_guest.id
    assert_redirected_to root_path

    # Can't view users new form
    get :new
    assert_redirected_to root_path

    # Can't view users edit form
    get :edit, :id => @user_guest.id
    assert_redirected_to root_path

    # Can't create users
    post :create, :user => @create_hash
    assert_redirected_to root_path
    # Check that the user hasn't been created
    assert_not User.where(:email => @create_hash[:email]).first

    # Can't update users
    put :update, :id => @user_guest.id, :user => {:name => "Name test"}
    assert_redirected_to root_path
    # Check that there isn't any change
    @user_guest.reload
    assert_not_equal @user_guest.name, "Name test"

    # Can't destroy users
    delete :destroy, :id => @user_guest.id
    assert_redirected_to root_path
    # Check that theuser already exists
    assert User.where(:_id => @user_guest.id).first

    sign_out :user
  end

  test "read only actions should be the only accesible for normal users" do
    sign_in :user, @user_normal

    # Can index users
    get :index
    assert_response :success
    assert_template :layout => :application
    assert_template :index

    # Can view users
    get :show, :id => @user_normal.id
    assert_response :success
    assert_template :layout => :application
    assert_template :show

    # Can't view users new form
    get :new
    assert_redirected_to root_path

    # Can't view users edit form
    get :edit, :id => @user_normal.id
    assert_redirected_to root_path

    # Can't create users
    post :create, :user => @create_hash
    assert_redirected_to root_path
    # Check that the user hasn't been created
    assert_not User.where(:email => @create_hash[:email]).first

    # Can't update users
    put :update, :id => @user_normal.id, :user => {:name => "Name test"}
    assert_redirected_to root_path
    # Check that there isn't any change
    @user_normal.reload
    assert_not_equal @user_normal.name, "Name test"

    # Can't destroy users
    delete :destroy, :id => @user_normal.id
    assert_redirected_to root_path
    # Check that theuser already exists
    assert User.where(:_id => @user_normal.id).first

    sign_out :user
  end

  test "read and write actions should be accesible for administrator users" do
    sign_in :user, @user_admin

    # Can index users
    get :index
    assert_response :success
    assert_template :layout => :application
    assert_template :index

    # Can view users
    get :show, :id => @user_admin.id
    assert_response :success
    assert_template :layout => :application
    assert_template :show

    # Can access to new form
    get :new
    assert_response :success
    assert_template :layout => :application
    assert_template :new

    # Can access to edit form
    get :edit, :id => @user_admin.id
    assert_response :success
    assert_template :layout => :application
    assert_template :edit

    # CREATE, UPDATE and DESTROY operations are test in separate tests.

    sign_out :user
  end

  test "should do actions over existing users only" do
    sign_in :user, @user_admin

    # Show action
    get :show, :id => "non-existing-id"
    assert_redirected_to users_path

    # Edit action
    get :edit, :id => "non-existing-id"
    assert_redirected_to users_path

    # Update actions
    put :update, :id => "non-existing-id", :user => {:name => "name change"}
    assert_redirected_to users_path

    # Destroy action
    count_before = User.all.count
    delete :destroy, :id => "non-existing-id"
    assert_redirected_to users_path
    assert_equal count_before, User.all.count

    sign_out :user
  end

  test "should create users with valid data only" do
    sign_in :user, @user_admin

    # Valid user
    post :create, :user => @create_hash

    # Should be created
    user = User.where(:email => @create_hash[:email]).first
    assert user
    assert_redirected_to user_path(user)

    # Invalid user (bad e-mail)
    modified_hash = @create_hash
    modified_hash[:email] = "bad-email"
    post :create, :user => modified_hash

    # Shouldn't be created (not passing validations)
    user = User.where(:email => modified_hash[:email]).first
    assert_not user
    assert_response :success
    assert_template :layout => :application
    assert_template :new

    sign_out :user
  end

  test "should update users with valid data only" do
    sign_in :user, @user_admin

    # Valid data
    put :update, :id => @user_normal.id, :user => {:name => "Name test"}

    # Should be updated
    @user_normal.reload
    assert_equal @user_normal.name, "Name test"
    assert_redirected_to user_path(@user_normal)

    # Invalid user (bad name length)
    put :update, :id => @user_normal.id, :user => {:name => "a"}

    # Shouldn't be updated (not passing validations)
    @user_normal.reload
    assert_not_equal @user_normal.name, "a"
    assert_response :success
    assert_template :layout => :application
    assert_template :edit

    sign_out :user
  end

  test "should update user password and send e-mail" do
    sign_in :user, @user_admin

    count_pre = UserMailerWorker.jobs.count

    # Change password
    put :update, :id => @user_normal.id, :user => {:change_password => "true"}
    count_post = UserMailerWorker.jobs.count
    # Should be one more job
    assert_equal count_pre+1, count_post

    # Should be redirected
    assert_redirected_to user_path(@user_normal)

    sign_out :user
  end

  test "should not change the privilege level of the current user" do
    sign_in :user, @user_admin

    # Try to change it's own level
    put :update, :id => @user_admin.id, :user => {:level => User::LEVEL_NORMAL}

    # Reload the data and checks
    @user_admin.reload
    assert_equal @user_admin.level, User::LEVEL_ADMINISTRATOR

    sign_out :user
  end

  test "should destroy users" do
    sign_in :user, @user_admin

    # Destroy user
    delete :destroy, :id => @user_normal.id

    # Destroyed user shouldn't be found in database.
    assert_not User.where(:_id => @user_normal.id).first
    assert_redirected_to users_path()

    sign_out :user
  end

  test "should not destroy the current user" do
    sign_in :user, @user_admin

    # Destroy user
    delete :destroy, :id => @user_admin.id

    # Destroyed user shouldn't be found in database.
    assert User.where(:_id => @user_admin.id).first
    assert_redirected_to user_path(@user_admin)

    sign_out :user
  end

  test "preferences should be accesible to anyone" do
    # Administrator users
    [@user_admin, @user_normal, @user_guest].each do |user|
        sign_in :user, user

        get :preferences
        assert_response :success
        assert_template :layout => :application
        assert_template :preferences

        # Valid preference update
        post :save_preferences, :user => {:name => user.name+" test", :current_password => user.password}
        assert_redirected_to root_path

        # Invalid current_password
        post :save_preferences, :user => {:name => user.name+" test", :current_password => "invalid"}
        assert_response :success
        assert_template :layout => :application
        assert_template :preferences

        # Invalid data introduced
        post :save_preferences, :user => {:name => "a", :current_password => user.password}
        assert_response :success
        assert_template :layout => :application
        assert_template :preferences

        # Can't change privilege level
        previous_level = user.level
        if (previous_level != User::LEVEL_NORMAL)
            post :save_preferences, :user => {:name => user.name, :current_password => user.password, :level => User::LEVEL_NORMAL}
        else
            post :save_preferences, :user => {:name => user.name, :current_password => user.password, :level => User::LEVEL_ADMINISTRATOR}
        end
        assert_redirected_to root_path
        user.reload
        assert_equal user.level, previous_level

        sign_out :user
    end
  end
end
