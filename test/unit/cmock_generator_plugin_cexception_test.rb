require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require 'cmock_generator_plugin_cexception'

class CMockGeneratorPluginCExceptionTest < Test::Unit::TestCase
  def setup
    create_mocks :config, :utils
    @config.expect.tab.returns("  ")
    @config.stubs!(:respond_to?).returns(true)
    @cmock_generator_plugin_cexception = CMockGeneratorPluginCException.new(@config, @utils)
  end

  def teardown
  end
  
  should "have set up internal accessors correctly on init" do
    assert_equal(@config, @cmock_generator_plugin_cexception.config)
    assert_equal(@utils,  @cmock_generator_plugin_cexception.utils)
    assert_equal("  ",    @cmock_generator_plugin_cexception.tab)
  end
  
  should "include the cexception library" do 
    expected = "#include \"Exception.h\"\n"
    @config.expect.cexception_include.returns(nil)
    returned = @cmock_generator_plugin_cexception.include_files
    assert_equal(expected, returned)
  end
  
  should "include the cexception library with a custom path if specified" do 
    expected = "#include \"../cexception/lib/Exception.h\"\n"
    @config.expect.cexception_include.returns("../cexception/lib/Exception.h")
    returned = @cmock_generator_plugin_cexception.include_files
    assert_equal(expected, returned)
  end
  
  should "add to control structure mock needs" do
    function = { :name => "Oak", :args => [], :return_type => "void" }
    @config.expect.expect_call_count_type.returns("uint32")
    @config.expect.cexception_throw_type.returns("EXCEPTION_TYPE")
    
    expected = ["  uint32 *Oak_ThrowOnCallCount;\n",
                "  uint32 *Oak_ThrowOnCallCount_Head;\n",
                "  uint32 *Oak_ThrowOnCallCount_Tail;\n",
                "  EXCEPTION_TYPE *Oak_ThrowValue;\n",
                "  EXCEPTION_TYPE *Oak_ThrowValue_Head;\n",
                "  EXCEPTION_TYPE *Oak_ThrowValue_Tail;\n"
               ]
    returned = @cmock_generator_plugin_cexception.instance_structure(function)
    assert_equal(expected, returned)
  end
  
  should "add mock function declarations for functions without arguments" do
    function = { :name => "Spruce", :args_string => "void", :return_type => "void" }
    @config.expect.cexception_throw_type.returns("EXCEPTION_TYPE")
    
    expected = "void Spruce_ExpectAndThrow(EXCEPTION_TYPE toThrow);\n"
    returned = @cmock_generator_plugin_cexception.mock_function_declarations(function)
    assert_equal(expected, returned)
  end
  
  should "add mock function declarations for functions with arguments" do
    function = { :name => "Spruce", :args_string => "const char* Petunia, uint32_t Lily", :return_type => "void" }
    @config.expect.cexception_throw_type.returns("EXCEPTION_TYPE")
  
    expected = "void Spruce_ExpectAndThrow(const char* Petunia, uint32_t Lily, EXCEPTION_TYPE toThrow);\n"
    returned = @cmock_generator_plugin_cexception.mock_function_declarations(function)
    assert_equal(expected, returned)
  end
  
  should "add nothing during implementation prefix" do
    assert(!@cmock_generator_plugin_cexception.respond_to?(:mock_implementation_prefix))
  end
  
  should "add a mock implementation" do
    function = {:name => "Cherry", :args => [], :return_type => "void"}
    @config.expect.cexception_throw_type.returns("EXCEPTION_TYPE")
  
    expected = ["\n",
                "  if((Mock.Cherry_ThrowOnCallCount != Mock.Cherry_ThrowOnCallCount_Tail) &&\n",
                "    (Mock.Cherry_ThrowValue != Mock.Cherry_ThrowValue_Tail))\n",
                "  {\n",
                "    if (*Mock.Cherry_ThrowOnCallCount && \n",
                "      (Mock.Cherry_CallCount == *Mock.Cherry_ThrowOnCallCount))\n",
                "    {\n",
                "      EXCEPTION_TYPE toThrow = *Mock.Cherry_ThrowValue;\n",
                "      Mock.Cherry_ThrowOnCallCount++;\n",
                "      Mock.Cherry_ThrowValue++;\n",
                "      Throw(toThrow);\n",
                "    }\n",
                "  }\n"
               ]
    returned = @cmock_generator_plugin_cexception.mock_implementation(function)
    assert_equal(expected, returned)
  end
  
  should "add mock interfaces for functions without arguments" do
    function = {:name => "Pear", :args_string => "void", :args => [], :return_type => "void"}
    @config.expect.expect_call_count_type.returns("uint32")
    @config.expect.cexception_throw_type.returns("EXCEPTION_TYPE")
    @utils.expect.code_add_base_expectation("Pear").returns("mock_retval_0")
    @utils.expect.code_insert_item_into_expect_array("uint32", "Mock.Pear_ThrowOnCallCount_Head", "Mock.Pear_CallsExpected").returns("mock_return_1")
    @utils.expect.code_insert_item_into_expect_array("EXCEPTION_TYPE", "Mock.Pear_ThrowValue_Head", "toThrow").returns("mock_return_2")
  
    expected = ["void Pear_ExpectAndThrow(EXCEPTION_TYPE toThrow)\n",
                "{\n",
                "mock_retval_0",
                "mock_return_1",
                "  Mock.Pear_ThrowOnCallCount = Mock.Pear_ThrowOnCallCount_Head;\n",
                "  Mock.Pear_ThrowOnCallCount += Mock.Pear_CallCount;\n",
                "mock_return_2",
                "  Mock.Pear_ThrowValue = Mock.Pear_ThrowValue_Head;\n",
                "  Mock.Pear_ThrowValue += Mock.Pear_CallCount;\n",
                "}\n\n"
               ]
    returned = @cmock_generator_plugin_cexception.mock_interfaces(function)
    assert_equal(expected, returned)
  end
  
  should "add a mock interfaces for functions with arguments" do
    function = {:name => "Pear", :args_string => "int blah", :args => [{ :type => "int", :name => "blah" }], :return_type => "void"}
    @config.expect.expect_call_count_type.returns("uint32")
    @config.expect.cexception_throw_type.returns("EXCEPTION_TYPE")
    @utils.expect.code_add_base_expectation("Pear").returns("mock_retval_0")
    @utils.expect.code_insert_item_into_expect_array("uint32", "Mock.Pear_ThrowOnCallCount_Head", "Mock.Pear_CallsExpected").returns("mock_return_1")
    @utils.expect.code_insert_item_into_expect_array("EXCEPTION_TYPE", "Mock.Pear_ThrowValue_Head", "toThrow").returns("mock_return_2")
    @utils.expect.create_call_list(function).returns("mock_return_3")
    
    expected = ["void Pear_ExpectAndThrow(int blah, EXCEPTION_TYPE toThrow)\n",
                "{\n",
                "mock_retval_0",
                "mock_return_1",
                "  Mock.Pear_ThrowOnCallCount = Mock.Pear_ThrowOnCallCount_Head;\n",
                "  Mock.Pear_ThrowOnCallCount += Mock.Pear_CallCount;\n",
                "mock_return_2",
                "  Mock.Pear_ThrowValue = Mock.Pear_ThrowValue_Head;\n",
                "  Mock.Pear_ThrowValue += Mock.Pear_CallCount;\n",
                "  ExpectParameters_Pear(mock_return_3);\n",
                "}\n\n"
               ]
    returned = @cmock_generator_plugin_cexception.mock_interfaces(function)
    assert_equal(expected, returned)
  end
  
  should "have nothing to say about verifying" do
    assert(!@cmock_generator_plugin_cexception.respond_to?(:mock_verify))
  end
  
  should "add necessary baggage to destroy function" do
    function = {:name => "Banana", :args_string => "", :args => [], :return_type => "void"}
    expected = ["  if(Mock.Banana_ThrowOnCallCount_Head)\n",
                "  {\n",
                "    free(Mock.Banana_ThrowOnCallCount_Head);\n",
                "    Mock.Banana_ThrowOnCallCount_Head=NULL;\n",
                "    Mock.Banana_ThrowOnCallCount_Tail=NULL;\n",
                "  }\n",
                "  if(Mock.Banana_ThrowValue_Head)\n",
                "  {\n",
                "    free(Mock.Banana_ThrowValue_Head);\n",
                "    Mock.Banana_ThrowValue_Head=NULL;\n",
                "    Mock.Banana_ThrowValue_Tail=NULL;\n",
                "  }\n"
               ]
    returned = @cmock_generator_plugin_cexception.mock_destroy(function)
    assert_equal(expected, returned)
  end
end
