require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require File.expand_path(File.dirname(__FILE__)) + "/../../lib/cmock_file_writer"

class CMockFileWriterTest < Test::Unit::TestCase
  def setup
    create_mocks :config
    @cmock_file_writer = CMockFileWriter.new(@config)
  end

  def teardown
  end
  
  should "have set up internal accessors correctly on init" do
    assert_equal(@config, @cmock_file_writer.config)
  end
  
  should "complain if a block was not specified when calling create" do
    begin
      @cmock_file_writer.create_file("test.txt")
      assert false, "Should Have Thrown An Error When Calling Without A Block"
    rescue
    end
  end
  
  should "create a file when requested and put a block of data in it" do
    @config.expect.mock_path.returns("C:\\")
    @config.expect.mock_path.returns("C:\\")
  
    @cmock_file_writer.create_file("test.txt") do |file, filename|
      file << "VICTORY!"
    end
    
    retval = File.open("C:\\test.txt", 'r').readlines[0]
    assert_equal "VICTORY!", retval
  end
  
end
