require 'test_helper'

class AlertRecordTest < ActiveSupport::TestCase
  def setup
    create_alert

    # MongoID hasn't got fixtures support :(
    @alert_record = AlertRecord.new(:open => true, :hosts => [@host], :service => @service, :alert => @alert)
  end

  def teardown
    Service.destroy_all
    Host.destroy_all
    Alert.destroy_all
    AlertRecord.destroy_all
  end

  test "should not save alert without a valid open state" do
    # Valid status
    @alert_record.open = true
    assert @alert_record.save
    assert_equal @alert_record.open, true

    # Valid status
    @alert_record.open = false
    assert @alert_record.save
    assert_equal @alert_record.open, false

    # Nil string
    @alert_record.open = nil
    assert_not @alert_record.save
    assert_not @alert_record.errors[:open].blank?

    # Empty string converted to boolean
    @alert_record.open = ""
    assert @alert_record.save
    assert_equal @alert_record.open, false

    # Boolean symbol converted to boolean
    @alert_record.open = :true
    assert @alert_record.save
    assert_equal @alert_record.open, true

    # Boolean symbol converted to boolean
    @alert_record.open = :false
    assert @alert_record.save
    assert_equal @alert_record.open, false

    # Boolean symbol converted to boolean
    @alert_record.open = :hihi
    assert @alert_record.save
    assert_equal @alert_record.open, false

    # Number converted to boolean
    @alert_record.open = 0
    assert @alert_record.save
    assert_equal @alert_record.open, false

    # Number converted to boolean
    @alert_record.open = 1
    assert @alert_record.save
    assert_equal @alert_record.open, true

    # Number converted to boolean
    @alert_record.open = 100
    assert @alert_record.save
    assert_equal @alert_record.open, true

    # Number converted to boolean
    @alert_record.open = -2
    assert @alert_record.save
    assert_equal @alert_record.open, false
  end

  test "should not save alert record without a valid open state" do
    # Valid status
    @alert_record.open = true
    assert @alert_record.save
    assert_equal @alert_record.open, true

    # Valid status
    @alert_record.open = false
    assert @alert_record.save
    assert_equal @alert_record.open, false

    # Nil string
    @alert_record.open = nil
    assert_not @alert_record.save
    assert_not @alert_record.errors[:open].blank?

    # Empty string converted to boolean
    @alert_record.open = ""
    assert @alert_record.save
    assert_equal @alert_record.open, false

    # Boolean symbol converted to boolean
    @alert_record.open = :true
    assert @alert_record.save
    assert_equal @alert_record.open, true

    # Boolean symbol converted to boolean
    @alert_record.open = :false
    assert @alert_record.save
    assert_equal @alert_record.open, false

    # Boolean symbol converted to boolean
    @alert_record.open = :hihi
    assert @alert_record.save
    assert_equal @alert_record.open, false

    # Number converted to boolean
    @alert_record.open = 0
    assert @alert_record.save
    assert_equal @alert_record.open, false

    # Number converted to boolean
    @alert_record.open = 1
    assert @alert_record.save
    assert_equal @alert_record.open, true

    # Number converted to boolean
    @alert_record.open = 100
    assert @alert_record.save
    assert_equal @alert_record.open, true

    # Number converted to boolean
    @alert_record.open = -2
    assert @alert_record.save
    assert_equal @alert_record.open, false
  end

  test "should not save alert record without a valid host" do
    # Valid hosts
    @alert_record.hosts = [@host]
    assert @alert_record.save

    # Invalid host
    @alert_record.host_ids = ["invalid_id"]
    assert_not @alert_record.save
    assert_not @alert_record.errors[:hosts].blank?

    # Invalid host
    @alert_record.host_ids = [""]
    assert_not @alert_record.save
    assert_not @alert_record.errors[:hosts].blank?

    # Invalid host
    @alert_record.host_ids = [nil]
    assert_not @alert_record.save
    assert_not @alert_record.errors[:hosts].blank?
  end

  test "should not save alert record without a valid service" do
    # Valid service
    @alert_record.service = @service
    assert @alert_record.save

    # Invalid service
    @alert_record.service_id = "invalid_id"
    assert_not @alert_record.save
    assert_not @alert_record.errors[:service].blank?

    # Invalid service
    @alert_record.service_id = ""
    assert_not @alert_record.save
    assert_not @alert_record.errors[:service].blank?

    # Invalid service
    @alert_record.service_id = nil
    assert_not @alert_record.save
    assert_not @alert_record.errors[:service].blank?
  end

  test "should not save alert record without a valid alert" do
    # Valid alert
    @alert_record.alert = @alert
    assert @alert_record.save

    # Invalid alert
    @alert_record.alert_id = "invalid_id"
    assert_not @alert_record.save
    assert_not @alert_record.errors[:alert].blank?

    # Invalid alert
    @alert_record.alert_id = ""
    assert_not @alert_record.save
    assert_not @alert_record.errors[:alert].blank?

    # Invalid alert
    @alert_record.alert_id = nil
    assert_not @alert_record.save
    assert_not @alert_record.errors[:alert].blank?
  end
end
