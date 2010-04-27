# ==========================================
#   CMock Project - Automatic Mock Generation for C
#   Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
#   [Released under MIT License. Please refer to license.txt for details]
# ========================================== 

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
    assert_equal(CMockConfig::CMockDefaultOptions[:cexception_include],    config.cexception_include)
  end
  
  should "replace only options specified in a hash" do
    test_includes = ['hello']
    test_attributes = ['blah', 'bleh']
    config = CMockConfig.new(:includes => test_includes, :attributes => test_attributes)
    assert_equal(CMockConfig::CMockDefaultOptions[:mock_path],              config.mock_path)
    assert_equal(test_includes,                                             config.includes)
    assert_equal(test_attributes,                                           config.attributes)
    assert_equal(CMockConfig::CMockDefaultOptions[:plugins],                config.plugins)
    assert_equal(CMockConfig::CMockDefaultOptions[:cexception_include],     config.cexception_include)
  end
  
  should "replace only options specified in a yaml file" do
    test_plugins = ['soda','pizza']
    test_include = 'MySillyException.h'
    config = CMockConfig.new("#{File.expand_path(File.dirname(__FILE__))}/cmock_config_test.yml")
    assert_equal(CMockConfig::CMockDefaultOptions[:mock_path],              config.mock_path)
    assert_equal(CMockConfig::CMockDefaultOptions[:includes],               config.includes)
    assert_equal(test_plugins,                                              config.plugins)
    assert_equal(test_include,                                              config.cexception_include)
  end
end
