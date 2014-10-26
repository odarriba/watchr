require 'test_helper'

class ServiceTest < ActiveSupport::TestCase
  def setup
    # MongoID hasn't got fixtures support :(
    @service = Service.new(:name => "Test Service", :description => "Test service description.", :active => true, :probe => "dummy", :probe_config => {:value => 1}, :interval => 60, :clean_interval => 86400, :priority => Service::PRIORITY_NORMAL, :resume => :mean_value)
  end

  def teardown
    Service.destroy_all
  end

  test "should not save service without a valid name" do
    # Valid string
    @service.name = "Test Service"
    assert @service.save

    # Empty string
    @service.name = ""
    assert_not @service.save
    assert_not @service.errors[:name].blank?

    # Nil string
    @service.name = nil
    assert_not @service.save
    assert_not @service.errors[:name].blank?

    # Short string
    @service.name = "a"
    assert_not @service.save
    assert_not @service.errors[:name].blank?

    # Long string
    @service.name = "qwertyuiopasdfghjklñzxcvbnmqwertyuiopasdfghj"
    assert_not @service.save
    assert_not @service.errors[:name].blank?
  end

  test "should save service with or without a description" do
    # With description
    @service.description = "Test description"
    assert @service.save
    
    # Without description
    @service.description = ""
    assert @service.save
  end

  test "should not save service without a valid active status" do
    # Valid boolean
    @service.active = true
    assert @service.save

    # Valid boolean
    @service.active = false
    assert @service.save

    # Nil object
    @service.active = nil
    assert_not @service.save
    assert_not @service.errors[:active].blank?
  end

  test "should not save service without a valid probe" do
    # With a probe
    @service.probe = "dummy"
    assert @service.save
    
    # Without a existing probe
    @service.probe = "not_existing_probe"
    assert_not @service.save
    assert_not @service.errors[:probe].blank?

    # With a nil probe
    @service.probe = nil
    assert_not @service.save
    assert_not @service.errors[:probe].blank?
  end

  test "should not save service without a valid probe configuration" do
    # With a valid probe configuration
    @service.probe = "dummy"
    @service.probe_config = {:value => 2}
    assert @service.save

    # Without a valid probe config
    @service.probe = "dummy"
    @service.probe_config = {:notvalid => "notvalidone"}
    assert_not @service.save
    assert_not @service.errors[:probe_config].blank?
  end

  test "should not save service without a valid interval" do
    # With a valid interval
    @service.interval = 3
    assert @service.save

    # Without a valid interval
    @service.interval = 0
    assert_not @service.save
    assert_not @service.errors[:interval].blank?

    # Without a valid interval
    @service.interval = -1
    assert_not @service.save
    assert_not @service.errors[:interval].blank?

    # Without a valid interval
    @service.interval = false
    assert_not @service.save
    assert_not @service.errors[:interval].blank?

    # Without a valid interval
    @service.interval = true
    assert_not @service.save
    assert_not @service.errors[:interval].blank?

    # Without a valid interval
    @service.interval = nil
    assert_not @service.save
    assert_not @service.errors[:interval].blank?
  end

  test "should not save service without a valid clean_interval" do
    # With a valid clean_interval
    @service.clean_interval = 3
    assert @service.save

    # Without a valid clean_interval
    @service.clean_interval = 0
    assert_not @service.save
    assert_not @service.errors[:clean_interval].blank?

    # Without a valid clean_interval
    @service.clean_interval = -1
    assert_not @service.save
    assert_not @service.errors[:clean_interval].blank?

    # Without a valid clean_interval
    @service.clean_interval = false
    assert_not @service.save
    assert_not @service.errors[:clean_interval].blank?

    # Without a valid clean_interval
    @service.clean_interval = true
    assert_not @service.save
    assert_not @service.errors[:clean_interval].blank?

    # Without a valid clean_interval
    @service.clean_interval = nil
    assert_not @service.save
    assert_not @service.errors[:clean_interval].blank?
  end

  test "should save service with a valid priority" do
    Service::AVAILABLE_PRIORITIES.each do |prior|
      @service.priority = prior
      assert @service.save
    end
  end

  test "should not save a host without a vaild priority" do
    # Empty string
    @service.priority = ""
    assert_not @service.save
    assert_not @service.errors[:priority].blank?

    # String with negative number
    @service.priority = "-1"
    assert_not @service.save
    assert_not @service.errors[:priority].blank?

    # Invalid priority
    @service.priority = 69
    assert_not @service.save
    assert_not @service.errors[:priority].blank?

    # Invalid priority
    @service.priority = -1
    assert_not @service.save
    assert_not @service.errors[:priority].blank?

    # Nil priority
    @service.priority = nil
    assert_not @service.save
    assert_not @service.errors[:priority].blank?
  end

  test "should save service with a valid resume" do
    Service::AVAILABLE_RESUMES.each do |res|
      @service.resume = res
      assert @service.save
    end
  end

  test "should not save a host without a vaild resume" do
    # Empty string
    @service.resume = ""
    assert_not @service.save
    assert_not @service.errors[:resume].blank?

    # String with negative number
    @service.resume = "-1"
    assert_not @service.save
    assert_not @service.errors[:resume].blank?

    # Invalid resume
    @service.resume = 69
    assert_not @service.save
    assert_not @service.errors[:resume].blank?

    # Invalid resume
    @service.resume = -1
    assert_not @service.save
    assert_not @service.errors[:resume].blank?

    # Nil resume
    @service.resume = nil
    assert_not @service.save
    assert_not @service.errors[:resume].blank?
  end

  test "should be assignable to hosts" do
    create_host

    # Make the service persistent
    assert @service.save
    
    # Could add it
    @service.hosts << @host
    assert @service.save

    # Reload anc check the relation
    @service.reload
    @host.reload
    assert @service.hosts.include?(@host)
    assert @host.services.include?(@service)

    clean_db
  end

  test "should get probe" do
    # Returns a valid probe
    @service.probe = "dummy"
    assert_equal @service.get_probe, Watchr::DummyProbe

    # Don't return invalid probe
    @service.probe = "invalidprobe"
    assert_not @service.get_probe
  end

  test "should get available probes" do
    # Returns at least a known probe
    assert Service.available_probes.include?("dummy")
  end

  test "should recognise valid priorities" do
    # Test each priority
    Service::AVAILABLE_PRIORITIES.each do |prior|
      assert Service.valid_priority?(prior)
    end
  end

  test "should recognise valid resumes" do
    # Test each resume
    Service::AVAILABLE_RESUMES.each do |resume|
      assert Service.valid_resume?(resume)
    end
  end

  test "should recognise valid probes" do
    # Test each probe
    Service.available_probes.each do |probe|
      assert Service.valid_probe?(probe)
    end
  end

  test "should known if it's active" do
    # Active
    @service.active = true
    assert @service.is_active?

    # Not active
    @service.active = false
    assert_not @service.is_active?
  end
end
