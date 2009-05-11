require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require 'cmock_config'

class CMockConfigTest < Test::Unit::TestCase
  def setup
  end

  def teardown
  end
  
  should "use default settings when no parameters are specified" do
    config = CMockConfig.new
    assert_equal(CMockConfig::CMockDefaultOptions[:mock_path],             config.mock_path)
    assert_equal(CMockConfig::CMockDefaultOptions[:includes],              config.includes)
    assert_equal(CMockConfig::CMockDefaultOptions[:attributes],            config.attributes)
    assert_equal(CMockConfig::CMockDefaultOptions[:plugins],               config.plugins)
    assert_equal(CMockConfig::CMockDefaultOptions[:tab],                   config.tab)
    assert_equal(CMockConfig::CMockDefaultOptions[:expect_call_count_type],config.expect_call_count_type)
    assert_equal(CMockConfig::CMockDefaultOptions[:ignore_bool_type],      config.ignore_bool_type)
    assert_equal(CMockConfig::CMockDefaultOptions[:cexception_include],    config.cexception_include)
    assert_equal(CMockConfig::CMockDefaultOptions[:cexception_throw_type], config.cexception_throw_type)
  end
  
  should "replace only options specified in a hash" do
    test_includes = ['hello']
    test_attributes = ['blah', 'bleh']
    test_bool_type = 'bool'
    config = CMockConfig.new(:includes => test_includes, :ignore_bool_type => test_bool_type, :attributes => test_attributes)
    assert_equal(CMockConfig::CMockDefaultOptions[:mock_path],              config.mock_path)
    assert_equal(test_includes,                                             config.includes)
    assert_equal(test_attributes,                                           config.attributes)
    assert_equal(CMockConfig::CMockDefaultOptions[:plugins],                config.plugins)
    assert_equal(CMockConfig::CMockDefaultOptions[:tab],                    config.tab)
    assert_equal(CMockConfig::CMockDefaultOptions[:expect_call_count_type], config.expect_call_count_type)
    assert_equal(test_bool_type,                                            config.ignore_bool_type)
    assert_equal(CMockConfig::CMockDefaultOptions[:cexception_include],     config.cexception_include)
    assert_equal(CMockConfig::CMockDefaultOptions[:cexception_throw_type],  config.cexception_throw_type)
  end
  
  should "replace only options specified in a yaml file" do
    test_plugins = ['soda','pizza']
    test_throw_type = 'uint32'
    config = CMockConfig.new("#{File.expand_path(File.dirname(__FILE__))}/cmock_config_test.yml")
    assert_equal(CMockConfig::CMockDefaultOptions[:mock_path],              config.mock_path)
    assert_equal(CMockConfig::CMockDefaultOptions[:includes],               config.includes)
    assert_equal(test_plugins,                                              config.plugins)
    assert_equal(CMockConfig::CMockDefaultOptions[:tab],                    config.tab)
    assert_equal(CMockConfig::CMockDefaultOptions[:expect_call_count_type], config.expect_call_count_type)
    assert_equal(CMockConfig::CMockDefaultOptions[:ignore_bool_type],       config.ignore_bool_type)
    assert_equal(CMockConfig::CMockDefaultOptions[:cexception_include],     config.cexception_include)
    assert_equal(test_throw_type,                                           config.cexception_throw_type)
  end
end
