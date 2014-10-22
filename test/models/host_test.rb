require 'test_helper'

class HostTest < ActiveSupport::TestCase
  def setup
    # MongoID hasn't got fixtures support :(
    @host = Host.new(:name => "Test Host", :type => Host::TYPE_SERVER, :address => "google.com", :description => "Test host description.")
  end

  def teardown
    Host.destroy_all
  end

  test "should not save host without a valid name" do
    # Valid string
    @host.name = "Test Host"
    assert @host.save

    # Empty string
    @host.name = ""
    assert_not @host.save
    assert_not @host.errors[:name].blank?

    # Nil string
    @host.name = nil
    assert_not @host.save
    assert_not @host.errors[:name].blank?

    # Short string
    @host.name = "a"
    assert_not @host.save
    assert_not @host.errors[:name].blank?

    # Long string
    @host.name = "qwertyuiopasdfghjklñzxcvbnmqwertyuiopasdfghj"
    assert_not @host.save
    assert_not @host.errors[:name].blank?
  end

  test "should save host with or without a description" do
    # With description
    @host.description = "Test description"
    assert @host.save
    
    # Without description
    @host.description = ""
    assert @host.save
  end

  test "should not save host without a valid address" do
    # With a valid domain address
    @host.address = "google.com"
    assert @host.save

    # With a valid IP address
    @host.address = "8.8.8.8"
    assert @host.save
    
    # Without a valid domain address
    @host.address = "test.prueba"
    assert_not @host.save
    assert_not @host.errors[:address].blank?

    # Without a valid IP address
    @host.address = "1.2.3.4.5"
    assert_not @host.save
    assert_not @host.errors[:address].blank?
  end

  test "should not save host with a valid and repeated address" do
    # With a valid domain address
    @host.address = "google.com"
    assert @host.save

    # With a valid IP address
    @new_host = Host.new(:name => "Test Host 2", :type => Host::TYPE_ROUTER, :address => "google.com", :description => "Test host description 2.")
    assert_not @new_host.save
    assert_not @new_host.errors[:address].blank?
  end

  test "should save host with a valid host type" do
    # Router type
    @host.type = Host::TYPE_ROUTER
    assert @host.save

    # Switch type
    @host.type = Host::TYPE_SWITCH
    assert @host.save

    # Server type
    @host.type = Host::TYPE_SERVER
    assert @host.save

    # Computer type
    @host.type = Host::TYPE_COMPUTER
    assert @host.save

    # Generic type
    @host.type = Host::TYPE_GENERIC
    assert @host.save
  end

  test "should not save a host without a vaild host type" do
    # Empty string
    @host.type = ""
    assert_not @host.save
    assert_not @host.errors[:type].blank?

    # String with negative number
    @host.type = "-1"
    assert_not @host.save
    assert_not @host.errors[:type].blank?

    # Invalid type
    @host.type = 69
    assert_not @host.save
    assert_not @host.errors[:type].blank?

    # Invalid type
    @host.type = -1
    assert_not @host.save
    assert_not @host.errors[:type].blank?

    # Invalid type
    @host.type = :ROUTER
    assert_not @host.save
    assert_not @host.errors[:type].blank?

    # Nil type
    @host.type = nil
    assert_not @host.save
    assert_not @host.errors[:type].blank?
  end

  test "should resolve ip addresses" do
    # Resolve local domains
    @host.address = "localhost"
    assert @host.ip_address

    # Resolve domains
    @host.address = "google.com"
    assert @host.ip_address

    # Resolving IP addresses should end in the same string
    @host.address = "8.8.8.8"
    assert_equal @host.ip_address, "8.8.8.8"

    # Return nil when the domain doesn't exists
    @host.address = "test.prueba"
    assert_not @host.ip_address

    # Return nil when the IP address isn't correct
    @host.address = "1.2.3.4.5"
    assert_not @host.ip_address
  end

  test "should recognise the assigned host type" do
    # Router host type
    @host.type = Host::TYPE_ROUTER
    assert Host.valid_type?(@host.type)
    assert @host.is_router?
    assert_not @host.is_switch?
    assert_not @host.is_server?
    assert_not @host.is_computer?
    assert_not @host.is_generic?

    # Switch host type
    @host.type = Host::TYPE_SWITCH
    assert Host.valid_type?(@host.type)
    assert_not @host.is_router?
    assert @host.is_switch?
    assert_not @host.is_server?
    assert_not @host.is_computer?
    assert_not @host.is_generic?

    # Server host type
    @host.type = Host::TYPE_SERVER
    assert Host.valid_type?(@host.type)
    assert_not @host.is_router?
    assert_not @host.is_switch?
    assert @host.is_server?
    assert_not @host.is_computer?
    assert_not @host.is_generic?

    # Computer host type
    @host.type = Host::TYPE_COMPUTER
    assert Host.valid_type?(@host.type)
    assert_not @host.is_router?
    assert_not @host.is_switch?
    assert_not @host.is_server?
    assert @host.is_computer?
    assert_not @host.is_generic?

    # Generic host type
    @host.type = Host::TYPE_GENERIC
    assert Host.valid_type?(@host.type)
    assert_not @host.is_router?
    assert_not @host.is_switch?
    assert_not @host.is_server?
    assert_not @host.is_computer?
    assert @host.is_generic?
  end
end
