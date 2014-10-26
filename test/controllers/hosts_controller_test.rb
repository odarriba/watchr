require 'test_helper'

class HostsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def setup
    # Create test users
    create_users

    @create_hash = {:name => "Test Host", :type => Host::TYPE_ROUTER, :address => "google.com", :description => "Test host description.", :active => true}
  end

  def teardown
    clean_db
  end

  test "index and show should be accessible for anyone" do
    @host = Host.create(@create_hash)

    # Check for every privilege level
    [@user_admin, @user_normal, @user_guest].each do |user|
      sign_in :user, user

      # Can get index of hosts
      get :index
      assert_response :success
      assert_template :layout => :application
      assert_template :index

      # Can view hosts
      get :show, :id => @host.id
      assert_response :success
      assert_template :layout => :application
      assert_template :show

      sign_out :user
    end
  end

  test "read and write access should not be available to guest users" do
    # Log in using a guest privilege level user
    sign_in :user, @user_guest

    # Can't view host creation form
    get :new
    assert_redirected_to root_path

    # Can't create ohsts
    post :create, :host => @create_hash
    assert_redirected_to root_path
    # Check that the user hasn't been created
    assert_not Host.where(:name => @create_hash[:name]).first

    @host = Host.create(@create_hash)

    # Can't view users edit form
    get :edit, :id => @host.id
    assert_redirected_to root_path

    # Can't update users
    put :update, :id => @host.id, :host => {:name => "Name test"}
    assert_redirected_to root_path
    # Check that there isn't any change
    @host.reload
    assert_not_equal @host.name, "Name test"

    # Can't destroy users
    delete :destroy, :id => @host.id
    assert_redirected_to root_path
    # Check that theuser already exists
    assert Host.where(:_id => @host.id).first

    sign_out :user
  end

  test "read and write access should be available to non-guest users" do
    @host = Host.create(@create_hash)

    # Try with Normal and Administrator privilege users
    [@user_admin, @user_normal].each do |user|
      sign_in :user, user

      # Can index users
      get :index
      assert_response :success
      assert_template :layout => :application
      assert_template :index

      # Can view users
      get :show, :id => @host.id
      assert_response :success
      assert_template :layout => :application
      assert_template :show

      # Can access to new form
      get :new
      assert_response :success
      assert_template :layout => :application
      assert_template :new

      # Can access to edit form
      get :edit, :id => @host.id
      assert_response :success
      assert_template :layout => :application
      assert_template :edit

      # CREATE, UPDATE and DESTROY operations are test in separate tests.

      sign_out :user
    end
  end

  test "should create hosts with valid data only" do
    sign_in :user, @user_admin

    # Valid host
    post :create, :host => @create_hash

    # Should be created
    host = Host.where(:address => @create_hash[:address]).first
    assert host
    assert_redirected_to host_path(host)

    # Invalid host (bad address)
    modified_hash = @create_hash
    modified_hash[:address] = "1.2.3.4.5"
    post :create, :host => modified_hash

    # Shouldn't be created (not passing validations)
    host = Host.where(:address => modified_hash[:address]).first
    assert_not host
    assert_response :success
    assert_template :layout => :application
    assert_template :new

    sign_out :user
  end

  test "should update hosts with valid data only" do
    sign_in :user, @user_admin

    @host = Host.create(@create_hash)

    # Valid data
    put :update, :id => @host.id, :host => {:name => "Name test"}

    # Should be updated
    @host.reload
    assert_equal @host.name, "Name test"
    assert_redirected_to host_path(@host)

    # Invalid host changes (bad name length)
    put :update, :id => @host.id, :host => {:name => "a"}

    # Shouldn't be updated (not passing validations)
    @host.reload
    assert_not_equal @host.name, "a"
    assert_response :success
    assert_template :layout => :application
    assert_template :edit

    sign_out :user
  end

  test "should destroy hosts" do
    sign_in :user, @user_admin

    @host = Host.create(@create_hash)

    # Destroy host
    delete :destroy, :id => @host.id

    # Destroyed host shouldn't be found in database.
    assert_not Host.where(:_id => @host.id).first
    assert_redirected_to hosts_path()

    sign_out :user
  end

  test "should do actions over existing hosts only" do
    sign_in :user, @user_admin

    # Show action
    get :show, :id => "non-existing-id"
    assert_redirected_to hosts_path

    # Edit action
    get :edit, :id => "non-existing-id"
    assert_redirected_to hosts_path

    # Update actions
    put :update, :id => "non-existing-id", :user => {:name => "name change"}
    assert_redirected_to hosts_path

    # Destroy action
    count_before = Host.all.count
    delete :destroy, :id => "non-existing-id"
    assert_redirected_to hosts_path
    assert_equal count_before, Host.all.count

    sign_out :user
  end
end
