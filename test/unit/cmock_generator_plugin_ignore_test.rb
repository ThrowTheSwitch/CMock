require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require 'cmock_generator_plugin_ignore'

class CMockGeneratorPluginIgnoreTest < Test::Unit::TestCase
  def setup
    create_mocks :config, :utils
    @config.expect.tab.returns("  ")
    @config.stubs!(:respond_to?).returns(true)
    @cmock_generator_plugin_ignore = CMockGeneratorPluginIgnore.new(@config, @utils)
  end

  def teardown
  end
  
  should "have set up internal accessors correctly on init" do
    assert_equal(@config, @cmock_generator_plugin_ignore.config)
    assert_equal(@utils,  @cmock_generator_plugin_ignore.utils)
    assert_equal("  ",    @cmock_generator_plugin_ignore.tab)
  end
  
  should "not have any additional include file requirements" do
    assert(!@cmock_generator_plugin_ignore.respond_to?(:include_files))
  end
  
  should "add a required variable to the instance structure" do
    function = {:name => "Grass", :args => [], :return_type => "void"}
    @config.expect.ignore_bool_type.returns("BOOL")
  
    expected = "  BOOL Grass_IgnoreBool;\n"
    returned = @cmock_generator_plugin_ignore.instance_structure(function)
    assert_equal(expected, returned)
  end
  
  should "handle function declarations for functions without return values" do
    function = {:name => "Mold", :args_string => "void", :return_type => "void"}
    expected = "void Mold_Ignore(void);\n"
    returned = @cmock_generator_plugin_ignore.mock_function_declarations(function)
    assert_equal(expected, returned)
  end
  
  should "handle function declarations for functions that returns something" do
    function = {:name => "Fungus", :args_string => "void", :return_type => "const char*", :return_string => "const char* #{CMOCK_RETURN_PARAM_NAME}"}
    expected = "void Fungus_IgnoreAndReturn(const char* #{CMOCK_RETURN_PARAM_NAME});\n"
    returned = @cmock_generator_plugin_ignore.mock_function_declarations(function)
    assert_equal(expected, returned)
  end
  
  should "add required code to implementation prefix with void function" do
    function = {:name => "Mold", :args_string => "void", :return_type => "void"}
    expected = ["  if (Mock.Mold_IgnoreBool)\n",
                "  {\n",
                "    return;\n",
                "  }\n"
               ]
    returned = @cmock_generator_plugin_ignore.mock_implementation_prefix(function)
    assert_equal(expected, returned)
  end
  
  should "add required code to implementation prefix with return functions" do
    function = {:name => "Fungus", :args_string => "void", :return_type => "int"}
    @utils.expect.code_handle_return_value(function, "    ").returns("    mock_return_1")
    
    expected = ["  if (Mock.Fungus_IgnoreBool)\n",
                "  {\n",
                "    mock_return_1",
                "  }\n"
               ]
    returned = @cmock_generator_plugin_ignore.mock_implementation_prefix(function)
    assert_equal(expected, returned)
  end
  
  should "have nothing new for mock implementation" do
    assert(!@cmock_generator_plugin_ignore.respond_to?(:mock_implementation))
  end
  
  should "add a new mock interface for ignoring when function had no return value" do
    function = {:name => "Slime", :args => [], :args_string => "void", :return_type => "void"}
    expected = ["void Slime_Ignore(void)\n",
                "{\n",
                "  Mock.Slime_IgnoreBool = (unsigned char)1;\n",
                "}\n\n"
               ]
    returned = @cmock_generator_plugin_ignore.mock_interfaces(function)
    assert_equal(expected, returned)
  end
  
  should "add a new mock interface for ignoring when function has return value" do
    function = {:name => "Slime", :args => [], :args_string => "void", :return_type => "uint32", :return_string => "uint32 #{CMOCK_RETURN_PARAM_NAME}"}
    @utils.expect.code_insert_item_into_expect_array("uint32", "Mock.Slime_Return_Head", "toReturn").returns("mock_return_1")
    
    expected = ["void Slime_IgnoreAndReturn(uint32 #{CMOCK_RETURN_PARAM_NAME})\n",
                "{\n",
                "  Mock.Slime_IgnoreBool = (unsigned char)1;\n",
                "mock_return_1",
                "  Mock.Slime_Return = Mock.Slime_Return_Head;\n",
                "  Mock.Slime_Return += Mock.Slime_CallCount;\n",
                "}\n\n"
               ]
    returned = @cmock_generator_plugin_ignore.mock_interfaces(function)
    assert_equal(expected, returned)
  end
  
  should "have nothing new for mock verify" do
    assert(!@cmock_generator_plugin_ignore.respond_to?(:mock_verify))
  end
  
  
  should "have nothing new for mock destroy" do
    assert(!@cmock_generator_plugin_ignore.respond_to?(:mock_destroy))
  end
end
