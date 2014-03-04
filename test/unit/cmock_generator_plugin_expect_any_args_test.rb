# ==========================================
#   CMock Project - Automatic Mock Generation for C
#   Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
#   [Released under MIT License. Please refer to license.txt for details]
# ==========================================

require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require 'cmock_generator_plugin_expect_any_args.rb'

class CMockGeneratorPluginExpectAnyArgsTest < Test::Unit::TestCase
  def setup
    create_mocks :config, :utils
    @config.stubs!(:respond_to?).returns(true)
    @cmock_generator_plugin_expect_any_args = CMockGeneratorPluginExpectAnyArgs.new(@config, @utils)
  end

  def teardown
  end

  should "have set up internal accessors correctly on init" do
    assert_equal(@config, @cmock_generator_plugin_expect_any_args.config)
    assert_equal(@utils,  @cmock_generator_plugin_expect_any_args.utils)
    assert_equal(3,       @cmock_generator_plugin_expect_any_args.priority)
  end

  should "not have any additional include file requirements" do
    assert(!@cmock_generator_plugin_expect_any_args.respond_to?(:include_files))
  end

  should "handle function declarations for functions without return values" do
    function = {:name => "Mold", :args_string => "void", :return => test_return[:void]}
    expected = "#define Mold_ExpectAnyArgs() Mold_CMockExpectAnyArgs(__LINE__)\nvoid Mold_CMockExpectAnyArgs(UNITY_LINE_TYPE cmock_line);\n"
    returned = @cmock_generator_plugin_expect_any_args.mock_function_declarations(function)
    assert_equal(expected, returned)
  end

  should "handle function declarations for functions that returns something" do
    function = {:name => "Fungus", :args_string => "void", :return => test_return[:string]}
    expected = "#define Fungus_ExpectAnyArgsAndReturn(cmock_retval) Fungus_CMockExpectAnyArgsAndReturn(__LINE__, cmock_retval)\n"+
               "void Fungus_CMockExpectAnyArgsAndReturn(UNITY_LINE_TYPE cmock_line, const char* cmock_to_return);\n"
    returned = @cmock_generator_plugin_expect_any_args.mock_function_declarations(function)
    assert_equal(expected, returned)
  end

  should "add required code to implementation with void function" do
    function = {:name => "Mold", :args_string => "void", :return => test_return[:void]}
    expected = ["  if (cmock_call_instance->IgnoreMode == CMOCK_ARG_NONE)\n",
                "  {\n",
                "    return;\n",
                "  }\n"
               ].join
    returned = @cmock_generator_plugin_expect_any_args.mock_implementation(function)
    assert_equal(expected, returned)
  end

  should "add required code to implementation with return functions" do
    function = {:name => "Fungus", :args_string => "void", :return => test_return[:int]}
    retval = test_return[:int].merge({ :name => "cmock_call_instance->ReturnVal"})
    @utils.expect.code_assign_argument_quickly("Mock.Fungus_FinalReturn", retval).returns('  mock_retval_0')
    expected = ["  if (cmock_call_instance->IgnoreMode == CMOCK_ARG_NONE)\n",
                "  {\n",
                "    mock_retval_0",
                "    return cmock_call_instance->ReturnVal;\n",
                "  }\n"
               ].join
    returned = @cmock_generator_plugin_expect_any_args.mock_implementation(function)
    assert_equal(expected, returned)
  end

  should "add a new mock interface for ignoring when function had no return value" do
    function = {:name => "Slime", :args => [], :args_string => "void", :return => test_return[:void]}
    expected = ["void Slime_CMockExpectAnyArgs(UNITY_LINE_TYPE cmock_line)\n",
                "{\n",
                "mock_return_1",
                "  cmock_call_instance->IgnoreMode = CMOCK_ARG_NONE;\n",
                "}\n\n"
               ].join
    @utils.expect.code_add_base_expectation("Slime", true).returns("mock_return_1")
    returned = @cmock_generator_plugin_expect_any_args.mock_interfaces(function)
    assert_equal(expected, returned)
  end
end
