require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require File.expand_path(File.dirname(__FILE__)) + "/../../lib/cmock_generator"

class CMockGeneratorTest < Test::Unit::TestCase
  def setup
    create_mocks :config, :file_writer, :utils, :plugins
    @module_name = "PoutPoutFish"
    
    @config.expect.tab.returns("  ")
    @cmock_generator = CMockGenerator.new(@config, @module_name, @file_writer, @utils, @plugins)
  end

  def teardown
  end
  
  should "have set up internal accessors correctly on init" do
    assert_equal(@config,       @cmock_generator.config)
    assert_equal(@module_name,  @cmock_generator.module_name)
    assert_equal(@file_writer,  @cmock_generator.file_writer)
    assert_equal(@utils,        @cmock_generator.utils)
    assert_equal(@plugins,      @cmock_generator.plugins)
    assert_equal("Mock#{@module_name}", @cmock_generator.mock_name)
    assert_equal("  ",          @cmock_generator.tab)
  end
  
  #should "create a very basic pair of files when there was no parsed stuff" do
  #  test_file_handle = 5
  #  @file_writer.expect.create_file("Mock#{@module_name}.h").returns([test_file_handle, "MockTurtle.h"])
  #  parsed_stuff = { :functions => [], :includes => [], :externs => [] }
  #  @cmock_generator.create_mock(parsed_stuff)
  #end
end
