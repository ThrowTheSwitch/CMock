# ==========================================
#   CMock Project - Automatic Mock Generation for C
#   Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
#   [Released under MIT License. Please refer to license.txt for details]
# ========================================== 

require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require 'cmock_generator_plugin_cexception'

class CMockGeneratorPluginCexceptionTest < Test::Unit::TestCase
  def setup
    create_mocks :config, :utils
    @cmock_generator_plugin_cexception = CMockGeneratorPluginCexception.new(@config, @utils)
  end

  def teardown
  end
  
  should "have set up internal accessors correctly on init" do
    assert_equal(@config, @cmock_generator_plugin_cexception.config)
    assert_equal(@utils,  @cmock_generator_plugin_cexception.utils)
    assert_equal(7,       @cmock_generator_plugin_cexception.priority)
  end
  
  should "include the cexception library" do 
    expected = "#include \"CException.h\"\n"
    returned = @cmock_generator_plugin_cexception.include_files
    assert_equal(expected, returned)
  end
  
  should "add to typedef structure mock needs" do
    function = { :name => "Oak", :args => [], :return => test_return[:void] }
    expected = "  CEXCEPTION_T ExceptionToThrow;\n"
    returned = @cmock_generator_plugin_cexception.instance_typedefs(function)
    assert_equal(expected, returned)
  end
  
  should "add mock function declarations for functions without arguments" do
    function = { :name => "Spruce", :args_string => "void", :return => test_return[:void] }
    expected = "#define Spruce_ExpectAndThrow(cmock_to_throw) Spruce_CMockExpectAndThrow(__LINE__, cmock_to_throw)\n"+
               "void Spruce_CMockExpectAndThrow(UNITY_LINE_TYPE cmock_line, CEXCEPTION_T cmock_to_throw);\n"
    returned = @cmock_generator_plugin_cexception.mock_function_declarations(function)
    assert_equal(expected, returned)
  end
  
  should "add mock function declarations for functions with arguments" do
    function = { :name => "Spruce", :args_string => "const char* Petunia, uint32_t Lily", :args_call => "Petunia, Lily", :return  => test_return[:void] }
    expected = "#define Spruce_ExpectAndThrow(Petunia, Lily, cmock_to_throw) Spruce_CMockExpectAndThrow(__LINE__, Petunia, Lily, cmock_to_throw)\n" +
               "void Spruce_CMockExpectAndThrow(UNITY_LINE_TYPE cmock_line, const char* Petunia, uint32_t Lily, CEXCEPTION_T cmock_to_throw);\n"
    returned = @cmock_generator_plugin_cexception.mock_function_declarations(function)
    assert_equal(expected, returned)
  end
  
  should "add a mock implementation" do
    function = {:name => "Cherry", :args => [], :return => test_return[:void]}
    expected = "  if (cmock_call_instance->ExceptionToThrow != CEXCEPTION_NONE)\n  {\n" + 
               "    Throw(cmock_call_instance->ExceptionToThrow);\n  }\n"
    returned = @cmock_generator_plugin_cexception.mock_implementation(function)
    assert_equal(expected, returned)
  end
  
  should "add mock interfaces for functions without arguments" do
    function = {:name => "Pear", :args_string => "void", :args => [], :return  => test_return[:void]}
    @utils.expect.code_add_base_expectation("Pear").returns("mock_retval_0")
    @utils.expect.code_call_argument_loader(function).returns("")
  
    expected = ["void Pear_CMockExpectAndThrow(UNITY_LINE_TYPE cmock_line, CEXCEPTION_T cmock_to_throw)\n",
                "{\n",
                "mock_retval_0",
                "",
                "  cmock_call_instance->ExceptionToThrow = cmock_to_throw;\n",
                "}\n\n"
               ].join
    returned = @cmock_generator_plugin_cexception.mock_interfaces(function)
    assert_equal(expected, returned)
  end
  
  should "add a mock interfaces for functions with arguments" do
    function = {:name => "Pear", :args_string => "int blah", :args => [{ :type => "int", :name => "blah" }], :return  => test_return[:void]}
    @utils.expect.code_add_base_expectation("Pear").returns("mock_retval_0")
    @utils.expect.code_call_argument_loader(function).returns("mock_return_1")
    
    expected = ["void Pear_CMockExpectAndThrow(UNITY_LINE_TYPE cmock_line, int blah, CEXCEPTION_T cmock_to_throw)\n",
                "{\n",
                "mock_retval_0",
                "mock_return_1",
                "  cmock_call_instance->ExceptionToThrow = cmock_to_throw;\n",
                "}\n\n"
               ].join
    returned = @cmock_generator_plugin_cexception.mock_interfaces(function)
    assert_equal(expected, returned)
  end
  
end
