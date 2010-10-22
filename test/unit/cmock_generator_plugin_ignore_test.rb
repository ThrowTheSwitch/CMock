# ==========================================
#   CMock Project - Automatic Mock Generation for C
#   Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
#   [Released under MIT License. Please refer to license.txt for details]
# ========================================== 

require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require 'cmock_generator_plugin_ignore'

class CMockGeneratorPluginIgnoreTest < Test::Unit::TestCase
  def setup
    create_mocks :config, :utils
    @config.expect.ignore.returns(:args_and_calls)
    @config.stubs!(:respond_to?).returns(true)
    @cmock_generator_plugin_ignore = CMockGeneratorPluginIgnore.new(@config, @utils)
    
    @config.expect.ignore.returns(:args_only)
    @cmock_generator_plugin_ignore_just_args = CMockGeneratorPluginIgnore.new(@config, @utils)
  end

  def teardown
  end
  
  should "have set up internal accessors correctly on init" do
    assert_equal(@config, @cmock_generator_plugin_ignore.config)
    assert_equal(@utils,  @cmock_generator_plugin_ignore.utils)
    assert_equal(2,       @cmock_generator_plugin_ignore.priority)
  end
  
  should "not have any additional include file requirements" do
    assert(!@cmock_generator_plugin_ignore.respond_to?(:include_files))
  end
  
  should "add a required variable to the instance structure" do
    function = {:name => "Grass", :args => [], :return => test_return[:void]}
    expected = "  int Grass_IgnoreBool;\n"
    returned = @cmock_generator_plugin_ignore.instance_structure(function)
    assert_equal(expected, returned)
  end
  
  should "handle function declarations for functions without return values" do
    function = {:name => "Mold", :args_string => "void", :return => test_return[:void]}
    expected = "#define Mold_Ignore() Mold_CMockIgnore(__LINE__)\nvoid Mold_CMockIgnore(UNITY_LINE_TYPE cmock_line);\n"
    returned = @cmock_generator_plugin_ignore.mock_function_declarations(function)
    assert_equal(expected, returned)
  end
  
  should "handle function declarations for functions that returns something" do
    function = {:name => "Fungus", :args_string => "void", :return => test_return[:string]}
    expected = "#define Fungus_IgnoreAndReturn(cmock_retval) Fungus_CMockIgnoreAndReturn(__LINE__, cmock_retval)\n"+
               "void Fungus_CMockIgnoreAndReturn(UNITY_LINE_TYPE cmock_line, const char* cmock_to_return);\n"
    returned = @cmock_generator_plugin_ignore.mock_function_declarations(function)
    assert_equal(expected, returned)
  end
  
  should "add required code to implementation precheck with void function (when :args_and_calls)" do
    function = {:name => "Mold", :args_string => "void", :return => test_return[:void]}
    expected = ["  if (Mock.Mold_IgnoreBool)\n",
                "  {\n",
                "    return;\n",
                "  }\n"
               ].join
    returned = @cmock_generator_plugin_ignore.mock_implementation_for_ignores(function)
    assert_equal(expected, returned)
  end
  
  should "add required code to implementation precheck with return functions (when :args_and_calls)" do
    function = {:name => "Fungus", :args_string => "void", :return => test_return[:int]}
    retval = test_return[:int].merge({ :name => "cmock_call_instance->ReturnVal"})
    @utils.expect.code_assign_argument_quickly("Mock.Fungus_FinalReturn", retval).returns('  mock_retval_0')
    expected = ["  if (Mock.Fungus_IgnoreBool)\n",
                "  {\n",
                "    if (cmock_call_instance == NULL)\n",
                "      return Mock.Fungus_FinalReturn;\n",
                "    mock_retval_0",
                "    return cmock_call_instance->ReturnVal;\n",
                "  }\n"
               ].join
    returned = @cmock_generator_plugin_ignore.mock_implementation_for_ignores(function)
    assert_equal(expected, returned)
  end
  
  should "not add code to implementation prefix (when :args_only)" do
    function = {:name => "Fungus", :args_string => "void", :return => test_return[:int]}
    retval = test_return[:int].merge({ :name => "cmock_call_instance->ReturnVal"})
    expected = ""
    returned = @cmock_generator_plugin_ignore.mock_implementation_precheck(function)
    assert_equal(expected, returned)
  end
  
  should "add required code to implementation with void function (when :args_only)" do
    function = {:name => "Mold", :args_string => "void", :return => test_return[:void]}
    expected = ["  if (Mock.Mold_IgnoreBool)\n",
                "  {\n",
                "    return;\n",
                "  }\n"
               ].join
    returned = @cmock_generator_plugin_ignore_just_args.mock_implementation(function)
    assert_equal(expected, returned)
  end
  
  should "add required code to implementation with return functions (when :args_only)" do
    function = {:name => "Fungus", :args_string => "void", :return => test_return[:int]}
    retval = test_return[:int].merge({ :name => "cmock_call_instance->ReturnVal"})
    @utils.expect.code_assign_argument_quickly("Mock.Fungus_FinalReturn", retval).returns('  mock_retval_0')
    expected = ["  if (Mock.Fungus_IgnoreBool)\n",
                "  {\n",
                "    if (cmock_call_instance == NULL)\n",
                "      return Mock.Fungus_FinalReturn;\n",
                "    mock_retval_0",
                "    return cmock_call_instance->ReturnVal;\n",
                "  }\n"
               ].join
    returned = @cmock_generator_plugin_ignore_just_args.mock_implementation(function)
    assert_equal(expected, returned)
  end
  
  should "add a new mock interface for ignoring when function had no return value" do
    function = {:name => "Slime", :args => [], :args_string => "void", :return => test_return[:void]}
    expected = ["void Slime_CMockIgnore(UNITY_LINE_TYPE cmock_line)\n",
                "{\n",
                "  Mock.Slime_IgnoreBool = (int)1;\n",
                "}\n\n"
               ].join
    @config.expect.ignore.returns(:args_and_calls)
    returned = @cmock_generator_plugin_ignore.mock_interfaces(function)
    assert_equal(expected, returned)
  end
  
  should "add a new mock interface for ignoring when function had no return value and we are checking args only" do
    function = {:name => "Slime", :args => [], :args_string => "void", :return => test_return[:void]}
    expected = ["void Slime_CMockIgnore(UNITY_LINE_TYPE cmock_line)\n",
                "{\n",
                "mock_return_1",
                "  Mock.Slime_IgnoreBool = (int)1;\n",
                "}\n\n"
               ].join
    @config.expect.ignore.returns(:args_only)
    @utils.expect.code_add_base_expectation("Slime", true).returns("mock_return_1")
    returned = @cmock_generator_plugin_ignore.mock_interfaces(function)
    assert_equal(expected, returned)
  end
  
  should "add a new mock interface for ignoring when function has return value" do
    function = {:name => "Slime", :args => [], :args_string => "void", :return => test_return[:int]}
    @config.expect.ignore.returns(:args_and_calls)
    @utils.expect.code_add_base_expectation("Slime", false).returns("mock_return_1")
    expected = ["void Slime_CMockIgnoreAndReturn(UNITY_LINE_TYPE cmock_line, int cmock_to_return)\n",
                "{\n",
                "mock_return_1",
                "  cmock_call_instance->ReturnVal = cmock_to_return;\n",
                "  Mock.Slime_IgnoreBool = (int)1;\n",
                "}\n\n"
               ].join
    returned = @cmock_generator_plugin_ignore.mock_interfaces(function)
    assert_equal(expected, returned)
  end
  
end
