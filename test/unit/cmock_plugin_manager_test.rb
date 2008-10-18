require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require File.expand_path(File.dirname(__FILE__)) + "/../../lib/cmock_plugin_manager"

class CMockPluginManagerTest < Test::Unit::TestCase
  def setup
    create_mocks :config, :utils
    @cmock_plugins = CMockPluginManager.new(@config, @utils)
  end

  def teardown
  end
  
  should "have set up internal accessors correctly on init" do
    assert_equal(@config, @cmock_plugins.config)
    assert_equal(@utils,  @cmock_plugins.utils)
  end
  
  should "return all plugins by default" do
    @config.stubs!(:tab).returns("  ")
    @config.expect.use_cexception.returns(true)
    @config.expect.allow_ignore_mock.returns(true)
    test_plugins = @cmock_plugins.get_generator_plugins
    contained = { :expect => false, :ignore => false, :cexception => false }
    test_plugins.each do |plugin|
      contained[:expect]     = true   if plugin.instance_of?(CMockGeneratorPluginExpect)
      contained[:ignore]     = true   if plugin.instance_of?(CMockGeneratorPluginIgnore)
      contained[:cexception] = true   if plugin.instance_of?(CMockGeneratorPluginCException)
    end
    assert_equal(true, contained[:expect])
    assert_equal(true, contained[:ignore])
    assert_equal(true, contained[:cexception])
  end
  
  should "return restricted plugins based on config" do
    @config.stubs!(:tab).returns("  ")
    @config.expect.use_cexception.returns(false)
    @config.expect.allow_ignore_mock.returns(false)
    test_plugins = @cmock_plugins.get_generator_plugins
    contained = { :expect => false, :ignore => false, :cexception => false }
    test_plugins.each do |plugin|
      contained[:expect]     = true   if plugin.instance_of?(CMockGeneratorPluginExpect)
      contained[:ignore]     = true   if plugin.instance_of?(CMockGeneratorPluginIgnore)
      contained[:cexception] = true   if plugin.instance_of?(CMockGeneratorPluginCException)
    end
    assert_equal(true, contained[:expect])
    assert_equal(false,contained[:ignore])
    assert_equal(false,contained[:cexception])
  end
  
end
