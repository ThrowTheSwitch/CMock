require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require File.expand_path(File.dirname(__FILE__)) + "/../../lib/cmock_generator_utils"

class CMockGeneratorUtilsTest < Test::Unit::TestCase
  def setup
    create_mocks :config
    @config.expect.tab.returns("  ")
    @cmock_generator_utils = CMockGeneratorUtils.new(@config)
  end

  def teardown
  end
  
  should "have set up internal accessors correctly on init" do
    assert_equal(@config, @cmock_generator_utils.config)
    assert_equal("  ",    @cmock_generator_utils.tab)
  end
end
