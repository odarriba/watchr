require 'test_helper'

class ServicesControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def setup
    # Create test users
    create_users

    @create_hash = {:name => "Test Service", :description => "Test service description.", :active => true, :probe => "dummy", :probe_config => {:value => 1}, :interval => 60, :clean_interval => 86400, :priority => Service::PRIORITY_NORMAL, :resume => :mean_value}
  end

  def teardown
    clean_db
  end

  test "index, show and index_hosts should be accessible for anyone" do
    create_host
    create_service(@create_hash)

    # Check for every privilege level
    [@user_admin, @user_normal, @user_guest].each do |user|
      sign_in :user, user

      # Can get index of services
      get :index
      assert_response :success
      assert_template :layout => :application
      assert_template :index

      # Can view services
      get :show, :id => @service.id
      assert_response :success
      assert_template :layout => :application
      assert_template :show

      # Can view hosts assigned to service
      get :index_hosts, :id => @service.id
      assert_response :success
      assert_template :layout => :application
      assert_template :index_hosts

      sign_out :user
    end
  end

  test "read and write access should not be available to guest users" do
    create_host

    # Log in using a guest privilege level user
    sign_in :user, @user_guest

    # Can't view service creation form
    get :new
    assert_redirected_to root_path

    # Can't create services
    post :create, :service => @create_hash
    assert_redirected_to root_path
    # Check that the service hasn't been created
    assert_not Service.where(:name => @create_hash[:name]).first

    create_service(@create_hash)

    # Can't view service edit form
    get :edit, :id => @service.id
    assert_redirected_to root_path

    # Can't update services
    put :update, :id => @service.id, :service => {:name => "Name test"}
    assert_redirected_to root_path
    # Check that there isn't any change
    @service.reload
    assert_not_equal @service.name, "Name test"

    # Can't destroy services
    delete :destroy, :id => @service.id
    assert_redirected_to root_path
    # Check that the service already exists
    assert Service.where(:_id => @service.id).first

    # Can't assing a host to service
    post :new_host, {:id => @service.id, :host_id => @host.id}
    assert_redirected_to root_path
    @service.reload
    assert_equal @service.hosts.count, 0

    # Can't remove a host from service
    @service.hosts << @host
    @service.save

    delete :delete_host, {:id => @service.id, :host_id => @host.id}
    assert_redirected_to root_path
    @service.reload
    assert_equal @service.hosts.count, 1

    sign_out :user
  end

  test "read and write access should be available to non-guest users" do
    create_service(@create_hash)

    # Try with Normal and Administrator privilege users
    [@user_admin, @user_normal].each do |user|
      sign_in :user, user

      # Can index services
      get :index
      assert_response :success
      assert_template :layout => :application
      assert_template :index

      # Can view services
      get :show, :id => @service.id
      assert_response :success
      assert_template :layout => :application
      assert_template :show

      # Can access to new form
      get :new
      assert_response :success
      assert_template :layout => :application
      assert_template :new

      # Can access to edit form
      get :edit, :id => @service.id
      assert_response :success
      assert_template :layout => :application
      assert_template :edit

      # CREATE, UPDATE and DESTROY operations are test in separate tests.

      sign_out :user
    end
  end

  test "should create services with valid data only" do
    sign_in :user, @user_admin

    # Valid service
    post :create, {:service => @create_hash, :probe_config => @create_hash[:probe_config]}

    # Should be created
    service = Service.where(:name => @create_hash[:name]).first
    assert service
    assert_redirected_to service_path(service)

    # Invalid service (bad probe)
    modified_hash = @create_hash
    modified_hash[:probe] = "invalidprobe"
    post :create, {:service => modified_hash, :probe_config => @create_hash[:probe_config]}

    # Shouldn't be created (not passing validations)
    service = Service.where(:probe => modified_hash[:probe]).first
    assert_not service
    assert_response :success
    assert_template :layout => :application
    assert_template :new

    sign_out :user
  end

  test "should update services with valid data only" do
    create_service(@create_hash)

    sign_in :user, @user_admin

    # Valid data
    put :update, :id => @service.id, :service => {:name => "Name test"}

    # Should be updated
    @service.reload
    assert_equal @service.name, "Name test"
    assert_redirected_to service_path(@service)

    # Invalid service changes (bad name length)
    put :update, :id => @service.id, :service => {:name => "a"}

    # Shouldn't be updated (not passing validations)
    @service.reload
    assert_not_equal @service.name, "a"
    assert_response :success
    assert_template :layout => :application
    assert_template :edit

    sign_out :user
  end

  test "should destroy services" do
    create_service(@create_hash)

    sign_in :user, @user_admin

    # Destroy service
    delete :destroy, :id => @service.id

    # Destroyed service shouldn't be found in database.
    assert_not Service.where(:_id => @service.id).first
    assert_redirected_to services_path()

    sign_out :user
  end

  test "should not show, assign or delete services if no host exists" do
    create_service(@create_hash)

    sign_in :user, @user_admin

    # Index hosts action
    request.env["HTTP_REFERER"] = services_path()
    get :index_hosts, {:id => @service.id}
    assert_redirected_to services_path()

    # Assign new host action
    request.env["HTTP_REFERER"] = services_path()
    post :new_host, {:id => @service.id, :host_id => "nonexistinghost"}
    assert_redirected_to services_path()

    # Delte a host assignation action
    request.env["HTTP_REFERER"] = services_path()
    delete :delete_host, {:id => @service.id, :host_id => "nonexistinghost"}
    assert_redirected_to services_path()
  end

  test "should assign hosts to service" do
    create_host
    create_service(@create_hash)

    sign_in :user, @user_admin

    # Can't assing an inexistent host to service
    post :new_host, {:id => @service.id, :host_id => "invalidhost"}
    assert_redirected_to service_hosts_path(@service)

    @service.reload
    assert_equal @service.hosts.count, 0

    # Can assing a host to service
    post :new_host, {:id => @service.id, :host_id => @host.id}
    assert_redirected_to service_hosts_path(@service)

    @service.reload
    assert_equal @service.hosts.count, 1

    sign_out :user
  end

  test "should remove hosts to service" do
    create_host
    create_service(@create_hash)

    @service.hosts << @host
    @service.save

    sign_in :user, @user_admin

    # Can't remove an inexistent host to service
    delete :delete_host, {:id => @service.id, :host_id => "invalidhost"}
    assert_redirected_to service_hosts_path(@service)

    @service.reload
    assert_equal @service.hosts.count, 1

    # Can remove a host from the service
    delete :delete_host, {:id => @service.id, :host_id => @host.id}
    assert_redirected_to service_hosts_path(@service)

    @service.reload
    assert_equal @service.hosts.count, 0

    sign_out :user
  end

  test "should do actions over existing services only" do
    create_host

    sign_in :user, @user_admin

    # Show action
    get :show, :id => "non-existing-id"
    assert_redirected_to services_path

    # Edit action
    get :edit, :id => "non-existing-id"
    assert_redirected_to services_path

    # Update actions
    put :update, :id => "non-existing-id", :service => {:name => "Name change"}
    assert_redirected_to services_path

    # Assing a host to service
    post :new_host, {:id => "non-existing-id", :host_id => @host.id}
    assert_redirected_to services_path

    # Remove a host from service
    delete :delete_host, {:id => "non-existing-id", :host_id => @host.id}
    assert_redirected_to services_path

    # Destroy action
    count_before = Service.all.count
    delete :destroy, :id => "non-existing-id"
    assert_redirected_to services_path
    assert_equal count_before, Service.all.count

    sign_out :user
  end
end
