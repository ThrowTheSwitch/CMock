# ==========================================
#   CMock Project - Automatic Mock Generation for C
#   Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
#   [Released under MIT License. Please refer to license.txt for details]
# ========================================== 

require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require 'cmock_generator_plugin_array'

class CMockGeneratorPluginArrayTest < Test::Unit::TestCase
  def setup
    create_mocks :config, :utils
    
    #no strict ordering
    @config.expect.when_ptr.returns(:compare_data)
    @config.expect.enforce_strict_ordering.returns(false)
    @config.stubs!(:respond_to?).returns(true)
    @utils.expect.helpers.returns({})
    @cmock_generator_plugin_array = CMockGeneratorPluginArray.new(@config, @utils)
  end

  def teardown
  end
  
  should "have set up internal accessors correctly on init" do
    assert_equal(@config, @cmock_generator_plugin_array.config)
    assert_equal(@utils,  @cmock_generator_plugin_array.utils)
    assert_equal(nil,     @cmock_generator_plugin_array.unity_helper)
    assert_equal(8,       @cmock_generator_plugin_array.priority)
  end
  
  should "not include any additional include files" do 
    assert(!@cmock_generator_plugin_array.respond_to?(:include_files))
  end
  
  should "not add to typedef structure for functions of style 'int* func(void)'" do
    function = {:name => "Oak", :args => [], :return => test_return[:int_ptr]}
    returned = @cmock_generator_plugin_array.instance_typedefs(function)
    assert_equal("", returned)
  end
  
  should "add to tyepdef structure mock needs of functions of style 'void func(int chicken, int* pork)'" do
    function = {:name => "Cedar", :args => [{ :name => "chicken", :type => "int", :ptr? => false}, { :name => "pork", :type => "int*", :ptr? => true}], :return => test_return[:void]}
    expected = "  int Expected_pork_Depth;\n"
    returned = @cmock_generator_plugin_array.instance_typedefs(function)
    assert_equal(expected, returned)
  end
  
  should "not add an additional mock interface for functions not containing pointers" do
    function = {:name => "Maple", :args_string => "int blah", :return  => test_return[:string], :contains_ptr? => false}
    returned = @cmock_generator_plugin_array.mock_function_declarations(function)
    assert_nil(returned)
  end
  
  should "add another mock function declaration for functions of style 'void func(int* tofu)'" do
    function = {:name => "Pine", 
                :args => [{ :type => "int*",
                           :name => "tofu",
                           :ptr? => true,
                         }],
                :return => test_return[:void], 
                :contains_ptr? => true }
    
    expected = "#define #{function[:name]}_ExpectWithArray(tofu, tofu_Depth) #{function[:name]}_CMockExpectWithArray(__LINE__, tofu, tofu_Depth)\n" +
               "void #{function[:name]}_CMockExpectWithArray(UNITY_LINE_TYPE cmock_line, int* tofu, int tofu_Depth);\n"
    returned = @cmock_generator_plugin_array.mock_function_declarations(function)
    assert_equal(expected, returned)
  end
  
  should "add another mock function declaration for functions of style 'const char* func(int* tofu)'" do
    function = {:name => "Pine", 
                :args => [{ :type => "int*",
                           :name => "tofu",
                           :ptr? => true,
                         }],
                :return => test_return[:string],
                :contains_ptr? => true }
    
    expected = "#define #{function[:name]}_ExpectWithArrayAndReturn(tofu, tofu_Depth, cmock_retval) #{function[:name]}_CMockExpectWithArrayAndReturn(__LINE__, tofu, tofu_Depth, cmock_retval)\n" +
               "void #{function[:name]}_CMockExpectWithArrayAndReturn(UNITY_LINE_TYPE cmock_line, int* tofu, int tofu_Depth, const char* cmock_to_return);\n"
    returned = @cmock_generator_plugin_array.mock_function_declarations(function)
    assert_equal(expected, returned)
  end
  
  should "not have a mock function implementation" do
    assert(!@cmock_generator_plugin_array.respond_to?(:mock_implementation))
  end

  should "not have a mock interfaces for functions of style 'int* func(void)'" do
    function = {:name => "Pear", :args => [], :args_string => "void", :return => test_return[:int_ptr]}
    returned = @cmock_generator_plugin_array.mock_interfaces(function)
    assert_nil(returned)
  end
  
  should "add mock interfaces for functions of style 'int* func(int* pescado, int pes)'" do
    function = {:name => "Lemon", 
                :args => [{ :type => "int*", :name => "pescado", :ptr? => true}, { :type => "int", :name => "pes", :ptr? => false}], 
                :args_string => "int* pescado, int pes", 
                :return  => test_return[:int_ptr], 
                :contains_ptr? => true }
    @utils.expect.code_add_base_expectation("Lemon").returns("mock_retval_0")
    
    expected = ["void Lemon_CMockExpectWithArrayAndReturn(UNITY_LINE_TYPE cmock_line, int* pescado, int pescado_Depth, int pes, int* cmock_to_return)\n",
                "{\n",
                "mock_retval_0",
                "  CMockExpectParameters_Lemon(cmock_call_instance, pescado, pescado_Depth, pes);\n",
                "  cmock_call_instance->ReturnVal = cmock_to_return;\n",
                "}\n\n"
               ].join
    returned = @cmock_generator_plugin_array.mock_interfaces(function).join
    assert_equal(expected, returned)
  end
  
end
