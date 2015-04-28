require 'test_helper'

class HostResultTest < ActiveSupport::TestCase
  def setup
    create_service
    create_host

    @service.hosts << @host
    @host.services << @service

    # MongoID hasn't got fixtures support :(
    @result = Result.new(:service => @service)
    @host_result = HostResult.new(:host => @host, :status => HostResult::STATUS_OK, :value => 2.0)
  end

  def teardown
    Service.destroy_all
    Host.destroy_all
    Result.destroy_all
  end

  test "status ok needs a value and doesn't have error" do
    # Valid host result
    host_result = HostResult.new(:host => @host, :status => HostResult::STATUS_OK, :value => 2.0, :error => "test error")
    assert host_result.valid?
    assert host_result.errors[:value].blank?
    assert_equal host_result.value, 2.0
    assert_equal host_result.error, nil

    # Invalid value
    host_result = HostResult.new(:host => @host, :status => HostResult::STATUS_OK, :value => nil)
    assert_not host_result.valid?
    assert_not host_result.errors[:value].blank?
  end

  test "status error doesn't have a value" do
    # Valid host result
    host_result = HostResult.new(:host => @host, :status => HostResult::STATUS_ERROR, :value => 2.0, :error => "test error")
    assert host_result.valid?
    assert host_result.errors[:value].blank?
    assert_equal host_result.value, nil
    assert_equal host_result.error, "test error"
  end

  test "status inactive doesn't have a value or error" do
    # Valid host result
    host_result = HostResult.new(:host => @host, :status => HostResult::STATUS_INACTIVE, :value => 2.0, :error => "test error")
    assert host_result.valid?
    assert host_result.errors[:value].blank?
    assert_equal host_result.value, nil
    assert_equal host_result.error, nil
  end

  test "status check functions work" do
    # Ok status result
    host_result = HostResult.new(:host => @host, :status => HostResult::STATUS_OK, :value => 2.0)

    assert host_result.is_ok?
    assert_not host_result.is_error?
    assert_not host_result.is_inactive?

    # Error status result
    host_result = HostResult.new(:host => @host, :status => HostResult::STATUS_ERROR, :error => "test error")

    assert_not host_result.is_ok?
    assert host_result.is_error?
    assert_not host_result.is_inactive?

    # Inactive status result
    host_result = HostResult.new(:host => @host, :status => HostResult::STATUS_INACTIVE)

    assert_not host_result.is_ok?
    assert_not host_result.is_error?
    assert host_result.is_inactive?
  end
end
