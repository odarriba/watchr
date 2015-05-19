require 'test_helper'

class AlertRecordTest < ActiveSupport::TestCase
  def setup
    create_alert

    # MongoID hasn't got fixtures support :(
    @alert_record = AlertRecord.new(:opened => true, :hosts => [@host], :service => @service, :alert => @alert)
  end

  def teardown
    Service.destroy_all
    Host.destroy_all
    Alert.destroy_all
    AlertRecord.destroy_all
  end

  test "should not save alert without a valid open state" do
    # Valid status
    @alert_record.opened = true
    assert @alert_record.save
    assert_equal @alert_record.opened, true

    # Valid status
    @alert_record.opened = false
    assert @alert_record.save
    assert_equal @alert_record.opened, false

    # Nil string
    @alert_record.opened = nil
    assert_not @alert_record.save
    assert_not @alert_record.errors[:opened].blank?

    # Empty string converted to boolean
    @alert_record.opened = ""
    assert @alert_record.save
    assert_equal @alert_record.opened, false

    # Boolean symbol converted to boolean
    @alert_record.opened = :true
    assert @alert_record.save
    assert_equal @alert_record.opened, true

    # Boolean symbol converted to boolean
    @alert_record.opened = :false
    assert @alert_record.save
    assert_equal @alert_record.opened, false

    # Boolean symbol converted to boolean
    @alert_record.opened = :hihi
    assert @alert_record.save
    assert_equal @alert_record.opened, false

    # Number converted to boolean
    @alert_record.opened = 0
    assert @alert_record.save
    assert_equal @alert_record.opened, false

    # Number converted to boolean
    @alert_record.opened = 1
    assert @alert_record.save
    assert_equal @alert_record.opened, true

    # Number converted to boolean
    @alert_record.opened = 100
    assert @alert_record.save
    assert_equal @alert_record.opened, true

    # Number converted to boolean
    @alert_record.opened = -2
    assert @alert_record.save
    assert_equal @alert_record.opened, false
  end
end
