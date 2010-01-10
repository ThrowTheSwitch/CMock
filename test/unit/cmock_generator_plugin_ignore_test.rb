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
    function = {:name => "Grass", :args => [], :return_type => "void"}
    expected = "  int Grass_IgnoreBool;\n"
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
    function = {:name => "Fungus", :args_string => "void", :return_type => "const char*", :return_string => "const char* cmock_to_return"}
    expected = "void Fungus_IgnoreAndReturn(const char* cmock_to_return);\n"
    returned = @cmock_generator_plugin_ignore.mock_function_declarations(function)
    assert_equal(expected, returned)
  end
  
  should "add required code to implementation with void function" do
    function = {:name => "Mold", :args_string => "void", :return_type => "void"}
    expected = ["  if (Mock.Mold_IgnoreBool)\n",
                "  {\n",
                "    return;\n",
                "  }\n"
               ].join
    returned = @cmock_generator_plugin_ignore.mock_implementation(function)
    assert_equal(expected, returned)
  end
  
  should "add required code to implementation with return functions" do
    function = {:name => "Fungus", :args_string => "void", :return_type => "int"}
    expected = ["  if (Mock.Fungus_IgnoreBool)\n",
                "  {\n",
                "    if (Mock.Fungus_Return != Mock.Fungus_Return_Tail)\n",
                "    {\n",
                "      int cmock_to_return = *Mock.Fungus_Return;\n",
                "      Mock.Fungus_Return++;\n",
                "      Mock.Fungus_CallCount++;\n",
                "      Mock.Fungus_CallsExpected++;\n",
                "      return cmock_to_return;\n",
                "    }\n",
                "    else\n",
                "    {\n",
                "      return *(Mock.Fungus_Return_Tail - 1);\n",
                "    }\n",
                "  }\n"
               ].join
    returned = @cmock_generator_plugin_ignore.mock_implementation(function)
    assert_equal(expected, returned)
  end
  
  should "add a new mock interface for ignoring when function had no return value" do
    function = {:name => "Slime", :args => [], :args_string => "void", :return_type => "void"}
    expected = ["\n",
                "void Slime_Ignore(void)\n",
                "{\n",
                "  Mock.Slime_IgnoreBool = (int)1;\n",
                "}\n\n"
               ].join
    returned = @cmock_generator_plugin_ignore.mock_interfaces(function)
    assert_equal(expected, returned)
  end
  
  should "add a new mock interface for ignoring when function has return value" do
    function = {:name => "Slime", :args => [], :args_string => "void", :return_type => "uint32", :return_string => "uint32 cmock_to_return"}
    @utils.expect.code_insert_item_into_expect_array("uint32", "Mock.Slime_Return", "cmock_to_return").returns("mock_return_1")
    
    expected = ["\n",
                "void Slime_IgnoreAndReturn(uint32 cmock_to_return)\n",
                "{\n",
                "  Mock.Slime_IgnoreBool = (int)1;\n",
                "mock_return_1\n",
                "  Mock.Slime_Return = Mock.Slime_Return_Head;\n",
                "  Mock.Slime_Return += Mock.Slime_CallCount;\n",
                "}\n\n"
               ].join
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
