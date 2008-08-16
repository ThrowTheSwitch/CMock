require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require File.expand_path(File.dirname(__FILE__)) + "/../../lib/cmock_generator_plugin_expect"

class CMockGeneratorPluginExpectTest < Test::Unit::TestCase
  def setup
    create_mocks :config, :utils
    @config.expect.tab.returns("  ")
    @cmock_generator_plugin_expect = CMockGeneratorPluginExpect.new(@config, @utils)
  end

  def teardown
  end
  
  should "have set up internal accessors correctly on init" do
    assert_equal(@config, @cmock_generator_plugin_expect.config)
    assert_equal(@utils,  @cmock_generator_plugin_expect.utils)
    assert_equal("  ",    @cmock_generator_plugin_expect.tab)
  end
  
  should "not include any additional include files" do 
    assert_equal([], @cmock_generator_plugin_expect.include_files)
  end
  
  should "add to control structure mock needs of functions of style 'void func(void)'" do
    function_name = "Oak"
    function_args_as_array = []
    function_return_type = "void"
    count_type = "uint32"
    
    @config.expect.call_count_type.returns(count_type)
    
    expected = ["  #{count_type} #{function_name}_CallCount;\n", 
                "  #{count_type} #{function_name}_CallsExpected;\n"
               ]
    returned = @cmock_generator_plugin_expect.instance_structure(function_name, function_args_as_array, function_return_type)
    assert_equal(expected, returned)
  end
  
  should "add to control structure mock needs of functions of style 'int func(void)'" do
    function_name = "Elm"
    function_args_as_array = []
    function_return_type = "int"
    count_type = "int16"
    
    @config.expect.call_count_type.returns(count_type)
    
    expected = ["  #{count_type} #{function_name}_CallCount;\n", 
                "  #{count_type} #{function_name}_CallsExpected;\n",
                "  #{function_return_type} *#{function_name}_Return;\n",
                "  #{function_return_type} *#{function_name}_Return_Head;\n",
                "  #{function_return_type} *#{function_name}_Return_HeadTail;\n"
               ]
    returned = @cmock_generator_plugin_expect.instance_structure(function_name, function_args_as_array, function_return_type)
    assert_equal(expected, returned)
  end
  
  should "add to control structure mock needs of functions of style 'void func(int chicken, char* pork)'" do
    function_name = "Cedar"
    function_args_as_array = [{ :name => "chicken", :type => "int"}, { :name => "pork", :type => "char*"}]
    function_return_type = "void"
    count_type = "unsigned char"
    
    @config.expect.call_count_type.returns(count_type)
    
    expected = ["  #{count_type} #{function_name}_CallCount;\n", 
                "  #{count_type} #{function_name}_CallsExpected;\n",
                "  int *#{function_name}_Expected_chicken;\n",
                "  int *#{function_name}_Expected_chicken_Head;\n",
                "  int *#{function_name}_Expected_chicken_HeadTail;\n",
                "  char* *#{function_name}_Expected_pork;\n",
                "  char* *#{function_name}_Expected_pork_Head;\n",
                "  char* *#{function_name}_Expected_pork_HeadTail;\n"
               ]
    returned = @cmock_generator_plugin_expect.instance_structure(function_name, function_args_as_array, function_return_type)
    assert_equal(expected, returned)
  end
  
  should "add to control structure mock needs of functions of style 'int func(float beef)'" do
    function_name = "Birch"
    function_args_as_array = [{ :name => "beef", :type => "float"}]
    function_return_type = "int"
    count_type = "unsigned int"
    
    @config.expect.call_count_type.returns(count_type)
    
    expected = ["  #{count_type} #{function_name}_CallCount;\n", 
                "  #{count_type} #{function_name}_CallsExpected;\n",
                "  #{function_return_type} *#{function_name}_Return;\n",
                "  #{function_return_type} *#{function_name}_Return_Head;\n",
                "  #{function_return_type} *#{function_name}_Return_HeadTail;\n",
                "  float *#{function_name}_Expected_beef;\n",
                "  float *#{function_name}_Expected_beef_Head;\n",
                "  float *#{function_name}_Expected_beef_HeadTail;\n",
               ]
    returned = @cmock_generator_plugin_expect.instance_structure(function_name, function_args_as_array, function_return_type)
    assert_equal(expected, returned)
  end
  
  should "add mock function declaration for functions of style 'void func(void)'" do
    function_name = "Maple"
    function_args = "void"
    function_return_type = "void"
    
    expected = "void #{function_name}_Expect(#{function_args});\n"
    returned = @cmock_generator_plugin_expect.mock_function_declarations(function_name, function_args, function_return_type)
    assert_equal(expected, returned)
  end
  
  should "add mock function declaration for functions of style 'int func(void)'" do
    function_name = "Spruce"
    function_args = "void"
    function_return_type = "int"
    
    expected = "void #{function_name}_ExpectAndReturn(#{function_return_type} toReturn);\n"
    returned = @cmock_generator_plugin_expect.mock_function_declarations(function_name, function_args, function_return_type)
    assert_equal(expected, returned)
  end
  
  should "add mock function declaration for functions of style 'const char* func(int tofu)'" do
    function_name = "Pine"
    function_args = "int tofu"
    function_return_type = "const char*"
    
    expected = "void #{function_name}_ExpectAndReturn(#{function_args}, #{function_return_type} toReturn);\n"
    returned = @cmock_generator_plugin_expect.mock_function_declarations(function_name, function_args, function_return_type)
    assert_equal(expected, returned)
  end
    
  should "not require anything for implementation prefix" do
    function_name = "Ash"
    function_return_type = "int"
    assert_equal([], @cmock_generator_plugin_expect.mock_implementation_prefix(function_name, function_return_type))
  end
  
  ####NEXT UP: Mock Implementation
end
