require 'test_helper'

class AlertTest < ActiveSupport::TestCase
  def setup
    create_service

    # MongoID hasn't got fixtures support :(
    @alert = Alert.new(:name => "Test Alert", :description => "Test alert description.", :active => true, :limit => 600, :condition => :greater_than, :target => :service, :service_id => @service.id)
  end

  def teardown
    Service.destroy_all
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

  test "should save an alert with a valid target" do
    # Test with all the targets defined
    Alert::AVAILABLE_TARGETS.each do |target|
      @alert.target = target
      assert @alert.save
      @alert.reload
      assert_equal @alert.target, target
    end
  end

  test "should not save an alert without a valid target" do
    # Invalid target
    @alert.target = "invalid_target"
    assert_not @alert.save
    assert_not @alert.errors[:target].blank?

    # Invalid symbolic target
    @alert.target = :invalid_target
    assert_not @alert.save
    assert_not @alert.errors[:target].blank?

    # Empty string
    @alert.target = ""
    assert_not @alert.save
    assert_not @alert.errors[:target].blank?

    # Number
    @alert.target = 0
    assert_not @alert.save
    assert_not @alert.errors[:target].blank?

    # Empty object
    @alert.target = nil
    assert_not @alert.save
    assert_not @alert.errors[:target].blank?
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

    # Invalid service
    @alert.service = nil
    assert_not @alert.save
    assert_not @alert.errors[:service].blank?
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

  test "should recognise valid targets" do
    # Test each condition
    Alert::AVAILABLE_TARGETS.each do |target|
      assert Alert.valid_target?(target)
    end
  end
end
