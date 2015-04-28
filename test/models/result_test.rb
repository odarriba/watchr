require 'test_helper'

class ResultTest < ActiveSupport::TestCase
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

  test "should save with a host result" do
    # Assign the host result
    @result.host_results << @host_result

    # Should save
    assert @result.save
  end

  test "should not save result without a host_result" do
    # Shouldn't save
    assert_not @result.save
    assert_not @result.errors[:host_results].blank?
  end

  test "should not save result with more than one host_result of the same host" do
    # Assign the host result
    @result.host_results << @host_result

    # Create and assign new HostResult of the same host
    host_result2 = HostResult.new(:host => @host, :status => HostResult::STATUS_OK, :value => 3.0)
    @result.host_results << host_result2
    
    # Shouldn't save
    assert_not @result.save
    assert_not @result.errors[:host_results].blank?
  end

  test "should not save result with a host_result of a host not linked to the service" do
    # Assign thehost result
    @result.host_results << @host_result

    create_host # Create a different host
    # This HostResult has an @host not liked to the service
    host_result2 = HostResult.new(:host => @host, :status => HostResult::STATUS_OK, :value => 2.0)
    @result.host_results << host_result2

    assert_not @result.save
    assert_not @result.errors[:host_results].blank?
  end

  test "get host result should work" do
  	# Assign the host result
  	@result.host_results << @host_result

  	# Obtain the HostResult object
  	host_result_obtained = @result.get_host_result(@host)
  	assert_equal @host_result, host_result_obtained
  end

  test "get host result value should work" do
    # Assign the host result
    @result.host_results << @host_result

    # Obtain the HostResult value
    value_obtained = @result.get_host_value(@host)
    assert_equal @host_result.value, value_obtained
  end

  test "get the values of the result" do
    # Create a host result
    host_result_one = HostResult.new(:host => @host, :status => HostResult::STATUS_OK, :value => 2.0)

    # Create another host result
    create_host
    host_result_two = HostResult.new(:host => @host, :status => HostResult::STATUS_OK, :value => 3.0)

    # Assign the host results
    @result.host_results << host_result_one
    @result.host_results << host_result_two

    values = @result.get_values

    assert_equal values.count, 2
    assert ((values[0] == host_result_one.value && values[1] == host_result_two.value) || (values[0] == host_result_two.value && values[1] == host_result_one.value))

    # Check sum value.
    @service.resume = :sum
    assert_equal @result.global_value, host_result_two.value+host_result_one.value

    # Check max value
    @service.resume = :max_value
    assert_equal @result.global_value, 3.0

    # Check min value
    @service.resume = :min_value
    assert_equal @result.global_value, 2.0

    # Check mean value
    @service.resume = :mean_value
    assert_equal @result.global_value, (host_result_two.value+host_result_one.value)/2
  end

  test "check all error checking functions" do
    # Create an error host result
    host_result_error = HostResult.new(:host => @host, :status => HostResult::STATUS_ERROR, :value => 2.0)

    @result.host_results << host_result_error

    assert @result.all_error?
    assert @result.any_error?
    assert_not @result.all_ok?
    assert_not @result.any_ok?

    # Create an ok host result
    host_result_ok = HostResult.new(:host => @host, :status => HostResult::STATUS_OK, :value => 2.0)

    @result.host_results << host_result_ok

    assert_not @result.all_error?
    assert @result.any_error?
    assert_not @result.all_ok?
    assert @result.any_ok?
  end

  test "check all ok checking functions" do
    # Create an ok host result
    host_result_ok = HostResult.new(:host => @host, :status => HostResult::STATUS_OK, :value => 2.0)

    @result.host_results << host_result_ok

    assert_not @result.all_error?
    assert_not @result.any_error?
    assert @result.all_ok?
    assert @result.any_ok?

    # Create an error host result
    host_result_error = HostResult.new(:host => @host, :status => HostResult::STATUS_ERROR, :value => 2.0)

    @result.host_results << host_result_error

    assert_not @result.all_error?
    assert @result.any_error?
    assert_not @result.all_ok?
    assert @result.any_ok?
  end
end
