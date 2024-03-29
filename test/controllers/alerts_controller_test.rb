require 'test_helper'

class AlertsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def setup
    # Create test users
    create_users
    # Create test service
    create_service
    # Create test host
    create_host

    @service.hosts << @host
    @service.save

    @create_hash = {:name => "Test Alert", :description => "Test alert description.", :active => true, :limit => 600, :condition => :greater_than, :condition_target => Alert::CONDITION_TARGET_ALL, :error_control => true, :service_id => @service.id, :host_ids => [@host.id]}
  end

  def teardown
    clean_db
  end

  test "index, show and index_hosts should be accessible for anyone" do
    create_alert(@create_hash)

    # Check for every privilege level
    [@user_admin, @user_normal, @user_guest].each do |user|
      sign_in :user, user

      # Can get index of alerts
      get :index
      assert_response :success
      assert_template :layout => :application
      assert_template :index

      # Can view alerts
      get :show, :id => @alert.id
      assert_response :success
      assert_template :layout => :application
      assert_template :show

      # Can view users subscribed to an alert
      get :index_users, :id => @alert.id
      assert_response :success
      assert_template :layout => :application
      assert_template :index_users

      # Can view alert records of an alert
      get :index_records, :id => @alert.id
      assert_response :success
      assert_template :layout => :application
      assert_template :index_records

      # Can view alert records of all alert
      get :index_records, :id => "all"
      assert_response :success
      assert_template :layout => :application
      assert_template :index_records

      # Now, create a AlertRecord
      @alert_record = AlertRecord.create(:open => true, :service => @service, :alert => @alert, :hosts => [@host])

      # Try again to view the records
      get :index_records, :id => @alert.id
      assert_response :success
      assert_template :layout => :application
      assert_template :index_records

      # Try again to view the records all an alert
      get :index_records, :id => "all"
      assert_response :success
      assert_template :layout => :application
      assert_template :index_records

      # View a record information
      get :show_record, :id => @alert_record.id
      assert_response :success
      assert_template :layout => :application
      assert_template :show_record

      sign_out :user
    end
  end

  test "read and write access should not be available to guest users" do
    # Log in using a guest privilege level user
    sign_in :user, @user_guest

    # Can't view alert creation form
    get :new
    assert_redirected_to root_path

    # Can't create alert
    post :create, :alert => @create_hash
    assert_redirected_to root_path
    # Check that the alert hasn't been created
    assert_not Alert.where(:name => @create_hash[:name]).first

    create_alert(@create_hash)

    # Can't view alert edit form
    get :edit, :id => @alert.id
    assert_redirected_to root_path

    # Can't update alerts
    put :update, :id => @alert.id, :alert => {:name => "Name test"}
    assert_redirected_to root_path
    # Check that there isn't any change
    @alert.reload
    assert_not_equal @alert.name, "Name test"

    # Can't destroy alerts
    delete :destroy, :id => @alert.id
    assert_redirected_to root_path
    # Check that the alert already exists
    assert Alert.where(:_id => @alert.id).first

    # Try to get host select box for new alerts
    xhr :get, :get_service_hosts, :id => "new", :service_id => @service.id, :format => "js"
    assert_redirected_to root_path

    # Try to get host select box for an specific alerts
    xhr :get, :get_service_hosts, :id => @alert.id, :service_id => @service.id, :format => "js"
    assert_redirected_to root_path

    # Can't subscribe a user to an alert
    [@user_admin, @user_normal, @user_guest].each do |user|
      post :new_user, {:id => @alert.id, :user_id => user.id}
      assert_redirected_to root_path
      @alert.reload
      assert_equal @alert.users.count, 0
    end

    # Can't unsubscribe a user from an alert
    [@user_admin, @user_normal, @user_guest].each do |user|
      @alert.users << user
      @alert.save
    end

    [@user_admin, @user_normal, @user_guest].each do |user|
      post :delete_user, {:id => @alert.id, :user_id => user.id}
      assert_redirected_to root_path
      @alert.reload
      assert_equal @alert.users.count, 3
    end

    sign_out :user
  end

  test "read and write access should be available to non-guest users" do
    create_alert(@create_hash)

    # Try with Normal and Administrator privilege users
    [@user_admin, @user_normal].each do |user|
      sign_in :user, user

      # Can index alerts
      get :index
      assert_response :success
      assert_template :layout => :application
      assert_template :index

      # Can view alerts
      get :show, :id => @alert.id
      assert_response :success
      assert_template :layout => :application
      assert_template :show

      # Can access to new form
      get :new
      assert_response :success
      assert_template :layout => :application
      assert_template :new

      # Can access to edit form
      get :edit, :id => @alert.id
      assert_response :success
      assert_template :layout => :application
      assert_template :edit

      # Try to get host select box for new alerts
      xhr :get, :get_service_hosts, :id => "new", :service_id => @service.id, :format => "js"
      assert_response :success
      assert_template :get_service_hosts

      # Try to get host select box for an specific alerts
      xhr :get, :get_service_hosts, :id => @alert.id, :service_id => @service.id, :format => "js"
      assert_response :success
      assert_template :get_service_hosts

      # CREATE, UPDATE and DESTROY operations are test in separate tests.

      sign_out :user
    end
  end

  test "should create alerts with valid data only" do
    # Try with Normal and Administrator privilege users
    [@user_admin, @user_normal].each do |user|
      sign_in :user, user

      alert = Alert.new(@create_hash)
      assert alert.valid?, alert.errors.inspect
      # Valid alert
      post :create, {:alert => @create_hash}

      # Should be created
      alert = Alert.where(:name => @create_hash[:name]).first
      assert alert
      assert_redirected_to alert_path(alert)

      alert.delete

      sign_out :user
    end

    # Try with Normal and Administrator privilege users
    [@user_admin, @user_normal].each do |user|
      sign_in :user, user

      # Invalid alert (bad condition)
      modified_hash = @create_hash
      modified_hash[:condition] = "invalidcondition"
      post :create, {:alert => modified_hash}

      # Shouldn't be created (not passing validations)
      alert = Alert.where(:alert => modified_hash[:condition]).first
      assert_not alert
      assert_response :success
      assert_template :layout => :application
      assert_template :new

      sign_out :user
    end
  end

  test "should update alerts with valid data only" do
    create_alert(@create_hash)

    # Try with Normal and Administrator privilege users
    [@user_admin, @user_normal].each do |user|
      sign_in :user, user

      # Valid data
      put :update, :id => @alert.id, :alert => {:name => "Name test"}

      # Should be updated
      @alert.reload
      assert_equal @alert.name, "Name test"
      assert_redirected_to alert_path(@alert)

      # Invalid alert changes (bad name length)
      put :update, :id => @alert.id, :alert => {:name => "a"}

      # Shouldn't be updated (not passing validations)
      @alert.reload
      assert_not_equal @alert.name, "a"
      assert_response :success
      assert_template :layout => :application
      assert_template :edit

      sign_out :user
    end
  end

  test "should destroy alerts" do
    create_alert(@create_hash)

    # Try with Normal and Administrator privilege users
    [@user_admin, @user_normal].each do |user|
      sign_in :user, user

      # Destroy alert
      delete :destroy, :id => @alert.id

      # Destroyed alert shouldn't be found in database.
      assert_not Alert.where(:_id => @alert.id).first
      assert_redirected_to alerts_path()

      sign_out :user
    end
  end

  test "should subscribe users to alert" do
    create_alert(@create_hash)

    # Try with Normal and Administrator privilege users
    [@user_admin, @user_normal].each do |user|
      sign_in :user, user

      # Can subscribe a user to an alert
      post :new_user, {:id => @alert.id, :user_id => @user_admin.id}
      assert_redirected_to alert_users_path(@alert)

      @alert.reload
      assert_equal @alert.users.count, 1

      # Can't subscribe an inexistent user
      post :new_user, {:id => @alert.id, :user_id => "invaliduser"}
      assert_redirected_to alert_users_path(@alert)

      @alert.reload
      assert_equal @alert.users.count, 1

      sign_out :user
    end
  end

  test "should unsubscribe users to alert" do
    create_alert(@create_hash)

    # Try with Normal and Administrator privilege users
    [@user_admin, @user_normal].each do |user|
      sign_in :user, user

      @alert.users << user
      @alert.save

      # Can't unsubscribe an inexistent user
      post :delete_user, {:id => @alert.id, :user_id => "invaliduser"}
      assert_redirected_to alert_users_path(@alert)

      @alert.reload
      assert_equal @alert.users.count, 1

      # Can unsubscribe a user to an alert
      delete :delete_user, {:id => @alert.id, :user_id => user.id}
      assert_redirected_to alert_users_path(@alert)

      @alert.reload
      assert_equal @alert.users.count, 0

      sign_out :user
    end
  end

  test "should do actions over existing alerts only" do
    sign_in :user, @user_admin

    # Show action
    get :show, :id => "non-existing-id"
    assert_redirected_to alerts_path()

    # Edit action
    get :edit, :id => "non-existing-id"
    assert_redirected_to alerts_path()

    # Update actions
    put :update, :id => "non-existing-id", :alert => {:name => "Name change"}
    assert_redirected_to alerts_path()

    # Subscribe a user to an alert
    post :new_user, {:id => "non-existing-id", :user_id => @user_admin.id}
    assert_redirected_to alerts_path()

    # Unsubscribe a user to an alert
    delete :delete_user, {:id => "non-existing-id", :user_id => @user_admin.id}
    assert_redirected_to alerts_path()

    # Destroy action
    count_before = Alert.all.count
    delete :destroy, :id => "non-existing-id"
    assert_redirected_to alerts_path()
    assert_equal count_before, Alert.all.count

    # View alert records of an unexisting alert
    get :index_records, :id => "non-existing-id"
    assert_redirected_to alerts_path()

    # View an unexisting alert record
    get :show_record, :id => "non-existing-id"
    assert_redirected_to alert_records_path()

    sign_out :user
  end
end
