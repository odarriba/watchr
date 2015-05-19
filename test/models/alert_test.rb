require 'test_helper'

class AlertTest < ActiveSupport::TestCase
  def setup
    create_service
    create_host

    @service.hosts << @host
    @service.save
    @host.save

    # MongoID hasn't got fixtures support :(
    @alert = Alert.new(:name => "Test Alert", :description => "Test alert description.", :active => true, :limit => 600, :condition => :greater_than, :condition_target => Alert::CONDITION_TARGET_ALL, :error_control => true, :service_id => @service.id, :hosts => [@host])
  end

  def teardown
    Service.destroy_all
    Host.destroy_all
    Alert.destroy_all
  end

  test "should not save alert without a valid name" do
    # Valid string
    @alert.name = "Test Alert"
    assert @alert.save

    # Empty string
    @alert.name = ""
    assert_not @alert.save
    assert_not @alert.errors[:name].blank?

    # Nil string
    @alert.name = nil
    assert_not @alert.save
    assert_not @alert.errors[:name].blank?

    # Short string
    @alert.name = "a"
    assert_not @alert.save
    assert_not @alert.errors[:name].blank?

    # Long string
    @alert.name = "qwertyuiopasdfghjklñzxcvbnmqwertyuiopasdfghj"
    assert_not @alert.save
    assert_not @alert.errors[:name].blank?
  end

  test "should save alert with or without a description" do
    # With description
    @alert.description = "Test description"
    assert @alert.save
    
    # Without description
    @alert.description = ""
    assert @alert.save
  end

  test "should not save alert without a valid active status" do
    # Valid boolean
    @alert.active = true
    assert @alert.save

    # Valid boolean
    @alert.active = false
    assert @alert.save

    # Nil object
    @alert.active = nil
    assert_not @alert.save
    assert_not @alert.errors[:active].blank?
  end

  test "should not save alert without a valid limit" do
    # With a valid limit
    @alert.limit = 600.5
    assert @alert.save

    # With a valid number string
    @alert.limit = "600.3"
    assert @alert.save
    # Saved converting string to int
    @alert.reload
    assert_equal @alert.limit, 600.3

    # With a valid limit
    @alert.limit = 0
    assert @alert.save

    # With a valid number string
    @alert.limit = "0"
    assert @alert.save
    # Saved converting string to int
    @alert.reload
    assert_equal @alert.limit, 0

    # With a valid limit
    @alert.limit = -100.12
    assert @alert.save

    # With a valid number string
    @alert.limit = "-100.13"
    assert @alert.save
    # Saved converting string to int
    @alert.reload
    assert_equal @alert.limit, -100.13
    
    # Without a valid limit
    @alert.limit = "nolimit"
    assert @alert.save
    # Saved converting string to int
    @alert.reload
    assert_equal @alert.limit, 0

    # Without a valid limit
    @alert.limit = :nolimit
    assert @alert.save
    # Saved converting symbol to int
    @alert.reload
    assert_equal @alert.limit, 0

    # Without a valid limit
    @alert.limit = nil
    assert_not @alert.save
    assert_not @alert.errors[:limit].blank?
  end

  test "should save an alert with a valid condition" do
    # Test with all the conditions defined
    Alert::AVAILABLE_CONDITIONS.each do |cond|
      @alert.condition = cond
      assert @alert.save
      @alert.reload
      assert_equal @alert.condition, cond
    end
  end

  test "should not save an alert without a valid condition" do
    # Invalid condition
    @alert.condition = "invalid_condition"
    assert_not @alert.save
    assert_not @alert.errors[:condition].blank?

    # Invalid symbolic condition
    @alert.condition = :invalid_condition
    assert_not @alert.save
    assert_not @alert.errors[:condition].blank?

    # Empty string
    @alert.condition = ""
    assert_not @alert.save
    assert_not @alert.errors[:condition].blank?

    # Number
    @alert.condition = 0
    assert_not @alert.save
    assert_not @alert.errors[:condition].blank?

    # Empty object
    @alert.condition = nil
    assert_not @alert.save
    assert_not @alert.errors[:condition].blank?
  end

  test "should save an alert with a valid condition target" do
    # Test with all the targets defined
    Alert::AVAILABLE_CONDITION_TARGETS.each do |condition_target|
      @alert.condition_target = condition_target
      assert @alert.save
      @alert.reload
      assert_equal @alert.condition_target, condition_target
    end
  end

  test "should not save an alert without a valid condition target" do
    # Invalid condition_target
    @alert.condition_target = "invalid_target"
    assert_not @alert.save
    assert_not @alert.errors[:condition_target].blank?

    # Invalid symbolic condition_target
    @alert.condition_target = :invalid_target
    assert_not @alert.save
    assert_not @alert.errors[:condition_target].blank?

    # Empty string
    @alert.condition_target = ""
    assert_not @alert.save
    assert_not @alert.errors[:condition_target].blank?

    # Number
    @alert.condition_target = 0
    assert_not @alert.save
    assert_not @alert.errors[:condition_target].blank?

    # Empty object
    @alert.condition_target = nil
    assert_not @alert.save
    assert_not @alert.errors[:condition_target].blank?
  end

  test "should not save alert without a valid error control status" do
    # Valid boolean
    @alert.error_control = true
    assert @alert.save

    # Valid boolean
    @alert.error_control = false
    assert @alert.save

    # Nil object
    @alert.error_control = nil
    assert_not @alert.save
    assert_not @alert.errors[:error_control].blank?
  end

  test "should not save an alert without a valid service" do
    # Invalid service
    @alert.service_id = "invalid_id"
    assert_not @alert.save
    assert_not @alert.errors[:service].blank?

    # Invalid service
    @alert.service_id = ""
    assert_not @alert.save
    assert_not @alert.errors[:service].blank?

    # Invalid service
    @alert.service_id = nil
    assert_not @alert.save
    assert_not @alert.errors[:service].blank?
  end

  test "should not save an alert without a valid host" do
    # Invalid service
    @alert.host_ids << "invalid_id"
    assert_not @alert.save
    assert_not @alert.errors[:hosts].blank?

    # Invalid service
    @alert.host_ids << ""
    assert_not @alert.save
    assert_not @alert.errors[:hosts].blank?

    # Invalid service
    @alert.host_ids << nil
    assert_not @alert.save
    assert_not @alert.errors[:hosts].blank?
  end

  test "should not save an alert with a host not linked to the service" do
    create_host

    # Host not linked
    @alert.hosts << @host
    assert_not @alert.save
    assert_not @alert.errors[:hosts].blank?

    # Now link it to the service and try again
    @service.hosts << @host
    @service.save
    @host.save

    assert @alert.save
  end

  test "should be assignable to users" do
    create_users

    # Make the alert persistent
    assert @alert.save

    # Test with all types of users
    [@user_admin, @user_normal, @user_guest].each do |user|
      # Could add it
      @alert.users << user
      assert @alert.save

      # Reload and check the relation
      @alert.reload
      user.reload
      assert @alert.users.include?(user)
      assert user.alerts.include?(@alert)
    end

    clean_db
  end

  test "should known if it's active" do
    # Active
    @alert.active = true
    assert @alert.is_active?

    # Not active
    @alert.active = false
    assert_not @alert.is_active?
  end

  test "should recognise valid conditions" do
    # Test each condition
    Alert::AVAILABLE_CONDITIONS.each do |condition|
      assert Alert.valid_condition?(condition)
    end
  end

  test "should recognise valid condition targets" do
    # Test each condition
    Alert::AVAILABLE_CONDITION_TARGETS.each do |target|
      assert Alert.valid_condition_target?(target)
    end
  end
end
