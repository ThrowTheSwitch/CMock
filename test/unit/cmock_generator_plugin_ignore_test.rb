require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require 'cmock_generator_plugin_ignore'

class CMockGeneratorPluginIgnoreTest < Test::Unit::TestCase
  def setup
    create_mocks :config, :utils
    @config.stubs!(:respond_to?).returns(true)
    @cmock_generator_plugin_ignore = CMockGeneratorPluginIgnore.new(@config, @utils)
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
    expected = "void Mold_Ignore(void);\n"
    returned = @cmock_generator_plugin_ignore.mock_function_declarations(function)
    assert_equal(expected, returned)
  end
  
  should "handle function declarations for functions that returns something" do
    function = {:name => "Fungus", :args_string => "void", :return => test_return[:string]}
    expected = "void Fungus_IgnoreAndReturn(const char* cmock_to_return);\n"
    returned = @cmock_generator_plugin_ignore.mock_function_declarations(function)
    assert_equal(expected, returned)
  end
  
  should "add required code to implementation with void function" do
    function = {:name => "Mold", :args_string => "void", :return => test_return[:void]}
    expected = ["  if (Mock.Mold_IgnoreBool)\n",
                "  {\n",
                "    return;\n",
                "  }\n"
               ].join
    returned = @cmock_generator_plugin_ignore.mock_implementation_precheck(function)
    assert_equal(expected, returned)
  end
  
  should "add required code to implementation with return functions" do
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
    returned = @cmock_generator_plugin_ignore.mock_implementation_precheck(function)
    assert_equal(expected, returned)
  end
  
  should "add a new mock interface for ignoring when function had no return value" do
    function = {:name => "Slime", :args => [], :args_string => "void", :return => test_return[:void]}
    expected = ["void Slime_Ignore(void)\n",
                "{\n",
                "  Mock.Slime_IgnoreBool = (int)1;\n",
                "}\n\n"
               ].join
    returned = @cmock_generator_plugin_ignore.mock_interfaces(function)
    assert_equal(expected, returned)
  end
  
  should "add a new mock interface for ignoring when function has return value" do
    function = {:name => "Slime", :args => [], :args_string => "void", :return => test_return[:int]}
    @utils.expect.code_add_base_expectation("Slime", false).returns("mock_return_1")
    expected = ["void Slime_IgnoreAndReturn(int cmock_to_return)\n",
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
