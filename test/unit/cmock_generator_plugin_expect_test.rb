require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require 'cmock_generator_plugin_expect'

class CMockGeneratorPluginExpectTest < Test::Unit::TestCase
  def setup
    create_mocks :config, :utils
    
    #no strict ordering
    @config.expect.tab.returns("  ")
    @config.expect.when_ptr_star.returns(:compare_data)
    @config.expect.enforce_strict_ordering.returns(false)
    @config.stubs!(:respond_to?).returns(true)
    @utils.expect.helpers.returns({})
    @cmock_generator_plugin_expect = CMockGeneratorPluginExpect.new(@config, @utils)
    
    #strict ordering
    @config.expect.tab.returns("  ")
    @config.expect.when_ptr_star.returns(:compare_data)
    @config.expect.enforce_strict_ordering.returns(true)
    @config.stubs!(:respond_to?).returns(true)
    @utils.expect.helpers.returns({})
    @cmock_generator_plugin_expect_strict = CMockGeneratorPluginExpect.new(@config, @utils)
  end

  def teardown
  end
  
  should "have set up internal accessors correctly on init" do
    assert_equal(@config, @cmock_generator_plugin_expect.config)
    assert_equal(@utils,  @cmock_generator_plugin_expect.utils)
    assert_equal("  ",    @cmock_generator_plugin_expect.tab)
    assert_equal(nil,     @cmock_generator_plugin_expect.unity_helper)
  end
  
  should "not include any additional include files" do 
    assert(!@cmock_generator_plugin_expect.respond_to?(:include_files))
  end
  
  should "add to control structure mock needs of functions of style 'void func(void)'" do
    function = {:name => "Oak", :args => [], :return_type => "void"}
    count_type = "uint32"
    @config.expect.expect_call_count_type.returns(count_type)
    
    expected = ["  #{count_type} #{function[:name]}_CallCount;\n", 
                "  #{count_type} #{function[:name]}_CallsExpected;\n"
               ]
    returned = @cmock_generator_plugin_expect.instance_structure(function)
    assert_equal(expected, returned)
  end
  
  should "add to control structure mock needs of functions of style 'int func(void)'" do
    function = {:name => "Elm", :args => [], :return_type => "int"}
    count_type = "int16"
    @config.expect.expect_call_count_type.returns(count_type)
    
    expected = ["  #{count_type} #{function[:name]}_CallCount;\n", 
                "  #{count_type} #{function[:name]}_CallsExpected;\n",
                "  #{function[:return_type]} *#{function[:name]}_Return;\n",
                "  #{function[:return_type]} *#{function[:name]}_Return_Head;\n",
                "  #{function[:return_type]} *#{function[:name]}_Return_Tail;\n"
               ]
    returned = @cmock_generator_plugin_expect.instance_structure(function)
    assert_equal(expected, returned)
  end
  
  should "add to control structure mock needs of functions of style 'void func(int chicken, char* pork)'" do
    function = {:name => "Cedar", :args => [{ :name => "chicken", :type => "int"}, { :name => "pork", :type => "char*"}], :return_type => "void"}
    count_type = "unsigned char"
    @config.expect.expect_call_count_type.returns(count_type)
    
    expected = ["  #{count_type} #{function[:name]}_CallCount;\n", 
                "  #{count_type} #{function[:name]}_CallsExpected;\n",
                "  int *#{function[:name]}_Expected_chicken;\n",
                "  int *#{function[:name]}_Expected_chicken_Head;\n",
                "  int *#{function[:name]}_Expected_chicken_Tail;\n",
                "  char* *#{function[:name]}_Expected_pork;\n",
                "  char* *#{function[:name]}_Expected_pork_Head;\n",
                "  char* *#{function[:name]}_Expected_pork_Tail;\n"
               ]
    returned = @cmock_generator_plugin_expect.instance_structure(function)
    assert_equal(expected, returned)
  end
  
  should "add to control structure mock needs of functions of style 'int func(float beef)'" do
    function = {:name => "Birch", :args => [{ :name => "beef", :type => "float"}], :return_type => "int"}
    count_type = "unsigned int"
    @config.expect.expect_call_count_type.returns(count_type)
    
    expected = ["  #{count_type} #{function[:name]}_CallCount;\n", 
                "  #{count_type} #{function[:name]}_CallsExpected;\n",
                "  #{function[:return_type]} *#{function[:name]}_Return;\n",
                "  #{function[:return_type]} *#{function[:name]}_Return_Head;\n",
                "  #{function[:return_type]} *#{function[:name]}_Return_Tail;\n",
                "  float *#{function[:name]}_Expected_beef;\n",
                "  float *#{function[:name]}_Expected_beef_Head;\n",
                "  float *#{function[:name]}_Expected_beef_Tail;\n",
               ]
    returned = @cmock_generator_plugin_expect.instance_structure(function)
    assert_equal(expected, returned)
  end
  
  should "add to control structure mock needs of functions of style 'void func(void)' and global ordering" do
    function = {:name => "Oak", :args => [], :return_type => "void"}
    count_type = "uint32"
    @config.expect.expect_call_count_type.returns(count_type)
    
    expected = ["  #{count_type} #{function[:name]}_CallCount;\n", 
                "  #{count_type} #{function[:name]}_CallsExpected;\n",
                "  int *#{function[:name]}_CallOrder;\n",
                "  int *#{function[:name]}_CallOrder_Head;\n",
                "  int *#{function[:name]}_CallOrder_Tail;\n"
               ]
    returned = @cmock_generator_plugin_expect_strict.instance_structure(function)
    assert_equal(expected, returned)
  end
  
  should "add mock function declaration for functions of style 'void func(void)'" do
    function = {:name => "Maple", :args_string => "void", :return_type => "void"}
    expected = ["void #{function[:name]}_Expect(#{function[:args_string]});\n"]
    returned = @cmock_generator_plugin_expect.mock_function_declarations(function)
    assert_equal(expected, returned)
  end
  
  should "add mock function declaration for functions of style 'int func(void)'" do
    function = {:name => "Spruce", :args_string => "void", :return_string => "int toReturn"}
    
    expected = ["void #{function[:name]}_ExpectAndReturn(#{function[:return_string]});\n"]
    returned = @cmock_generator_plugin_expect.mock_function_declarations(function)
    assert_equal(expected, returned)
  end
  
  should "add mock function declaration for functions of style 'const char* func(int tofu)'" do
    function = {:name => "Pine", :args_string => "int tofu", :return_string => "const char* toReturn"}
    
    expected = ["void #{function[:name]}_ExpectAndReturn(#{function[:args_string]}, #{function[:return_string]});\n"]
    returned = @cmock_generator_plugin_expect.mock_function_declarations(function)
    assert_equal(expected, returned)
  end
    
  should "not require anything for implementation prefix" do
    assert(!@cmock_generator_plugin_expect.respond_to?(:mock_implementation_prefix))
  end
  
  should "add mock function implementation for functions of style 'void func(void)'" do
    function = {:name => "Apple", :args => [], :return_type => "void"}
    expected = ["  Mock.Apple_CallCount++;\n",
                "  if (Mock.Apple_CallCount > Mock.Apple_CallsExpected)\n",
                "  {\n",
                "    TEST_FAIL(\"Function 'Apple' called more times than expected\");\n",
                "  }\n"
               ]
    returned = @cmock_generator_plugin_expect.mock_implementation(function)
    assert_equal(expected, returned)
  end
  
  should "add mock function implementation for functions of style 'int func(int veal, unsigned int sushi)'" do
    function = {:name => "Cherry", :args => [ { :type => "int", :name => "veal" }, { :type => "unsigned int", :name => "sushi" } ], :return_type => "int"}
    
    @utils.expect.code_verify_an_arg_expectation(function, function[:args][0][:type], function[:args][0][:name]).returns("mocked_retval_1")
    @utils.expect.code_verify_an_arg_expectation(function, function[:args][1][:type], function[:args][1][:name]).returns("mocked_retval_2")
    
    expected = ["  Mock.Cherry_CallCount++;\n",
                "  if (Mock.Cherry_CallCount > Mock.Cherry_CallsExpected)\n",
                "  {\n",
                "    TEST_FAIL(\"Function 'Cherry' called more times than expected\");\n",
                "  }\n",
                "mocked_retval_1",
                "mocked_retval_2"
               ]
    returned = @cmock_generator_plugin_expect.mock_implementation(function)
    assert_equal(expected, returned)
  end
  
  should "add mock function implementation using ordering if needed" do
    function = {:name => "Apple", :args => [], :return_type => "void"}
    expected = ["  Mock.Apple_CallCount++;\n",
                "  if (Mock.Apple_CallCount > Mock.Apple_CallsExpected)\n",
                "  {\n",
                "    TEST_FAIL(\"Function 'Apple' called more times than expected\");\n",
                "  }\n",
                "  {\n",
                "    int* p_expected = Mock.Apple_CallOrder;\n",
                "    ++GlobalVerifyOrder;\n",
                "    if (Mock.Apple_CallOrder != Mock.Apple_CallOrder_Tail)\n",
                "      Mock.Apple_CallOrder++;\n",
                "    if ((*p_expected != GlobalVerifyOrder) && (GlobalOrderError == NULL))\n",
                "    {\n",
                "      const char* ErrStr = \"Out of order function calls. Function 'Apple'\";\n",
                "      GlobalOrderError = malloc(46);\n",
                "      if (GlobalOrderError)\n",
                "        strcpy(GlobalOrderError, ErrStr);\n",
                "    }\n",
                "  }\n"
               ]
    @cmock_generator_plugin_expect.ordered = true
    returned = @cmock_generator_plugin_expect.mock_implementation(function)
    assert_equal(expected, returned)
  end
  
  should "add mock function implementation for functions of style 'void func(void)' and strict ordering" do
    function = {:name => "Apple", :args => [], :return_type => "void"}
    expected = ["  Mock.Apple_CallCount++;\n",
                "  if (Mock.Apple_CallCount > Mock.Apple_CallsExpected)\n",
                "  {\n",
                "    TEST_FAIL(\"Function 'Apple' called more times than expected\");\n",
                "  }\n",
                "  {\n",
                "    int* p_expected = Mock.Apple_CallOrder;\n",
                "    ++GlobalVerifyOrder;\n",
                "    if (Mock.Apple_CallOrder != Mock.Apple_CallOrder_Tail)\n",
                "      Mock.Apple_CallOrder++;\n",
                "    if ((*p_expected != GlobalVerifyOrder) && (GlobalOrderError == NULL))\n",
                "    {\n",
                "      const char* ErrStr = \"Out of order function calls. Function 'Apple'\";\n",
                "      GlobalOrderError = malloc(46);\n",
                "      if (GlobalOrderError)\n",
                "        strcpy(GlobalOrderError, ErrStr);\n",
                "    }\n",
                "  }\n"
               ]
    returned = @cmock_generator_plugin_expect_strict.mock_implementation(function)
    assert_equal(expected, returned)
  end
  
  should "add mock interfaces for functions of style 'void func(void)'" do
    @utils.expect.code_add_base_expectation("Pear").returns("mock_retval_0")
    function = {:name => "Pear", :args => [], :args_string => "void", :return_type => "void"}
    expected = ["void Pear_Expect(void)\n",
                "{\n",
                "mock_retval_0",
                "}\n\n"
               ]
    returned = @cmock_generator_plugin_expect.mock_interfaces(function)
    assert_equal(expected, returned)
  end
  
  should "add mock interfaces for functions of style 'unsigned short func(void)'" do
    function = {:name => "Orange", :args => [], :args_string => "void", :return_type => "unsigned short", :return_string => "unsigned short toReturn"}
    @utils.expect.code_add_base_expectation("Orange").returns("mock_retval_0")
    @utils.expect.code_insert_item_into_expect_array(function[:return_type], "Mock.Orange_Return_Head","toReturn").returns("mock_retval_1")
    
    expected = ["void Orange_ExpectAndReturn(unsigned short toReturn)\n",
                "{\n",
                "mock_retval_0",
                "mock_retval_1",
                "  Mock.Orange_Return = Mock.Orange_Return_Head;\n",
                "  Mock.Orange_Return += Mock.Orange_CallCount;\n",
                "}\n\n"
               ]
    returned = @cmock_generator_plugin_expect.mock_interfaces(function)
    assert_equal(expected, returned)
  end
  
  should "add mock interfaces for functions of style 'int func(char* pescado)'" do
    function = {:name => "Lemon", :args => [{ :type => "char*", :name => "pescado"}], :args_string => "char* pescado", :return_type => "int", :return_string => "int toReturn"}
    @utils.expect.code_add_an_arg_expectation(function, "char*", "pescado").returns("mock_retval_2")
    @utils.expect.code_add_base_expectation("Lemon").returns("mock_retval_0")
    @utils.expect.create_call_list(function).returns("mock_retval_3")
    @utils.expect.code_insert_item_into_expect_array(function[:return_type], "Mock.Lemon_Return_Head", 'toReturn').returns("mock_retval_1")
    
    expected = ["void ExpectParameters_Lemon(char* pescado)\n",
                "{\n",
                "mock_retval_2",
                "}\n\n",
                "void Lemon_ExpectAndReturn(char* pescado, int toReturn)\n",
                "{\n",
                "mock_retval_0",
                "  ExpectParameters_Lemon(mock_retval_3);\n",
                "mock_retval_1",
                "  Mock.Lemon_Return = Mock.Lemon_Return_Head;\n",
                "  Mock.Lemon_Return += Mock.Lemon_CallCount;\n",
                "}\n\n"
               ]
    returned = @cmock_generator_plugin_expect.mock_interfaces(function)
    assert_equal(expected, returned)
  end
  
  should "add mock interfaces for functions when using ordering" do
    function = {:name => "Pear", :args => [], :args_string => "void", :return_type => "void"}
    expected = ["void Pear_Expect(void)\n",
                "{\n",
                "mock_retval_0",
                "}\n\n"
               ]
    @cmock_generator_plugin_expect.ordered = true
    @utils.expect.code_add_base_expectation("Pear").returns("mock_retval_0")
    returned = @cmock_generator_plugin_expect.mock_interfaces(function)
    assert_equal(expected, returned)
  end
  
  should "add mock verify lines" do
    function = {:name => "Banana" }
  
    expected = ["  TEST_ASSERT_EQUAL_MESSAGE(Mock.Banana_CallsExpected, Mock.Banana_CallCount, \"Function 'Banana' called unexpected number of times.\");\n"]
    returned = @cmock_generator_plugin_expect.mock_verify(function)
    assert_equal(expected, returned)
  end
  
  should "add mock destroy for functions of style 'void func(void)'" do
    function = {:name => "Peach", :args => [], :return_type => "void" }
    expected = []
    returned = @cmock_generator_plugin_expect.mock_destroy(function)
    assert_equal(expected, returned)
  end
  
  should "add mock destroy for functions of style 'char func(void)'" do
    function = {:name => "Palm", :args => [], :return_type => "char" }
    expected = ["  if (Mock.Palm_Return_Head)\n",
                "  {\n",
                "    free(Mock.Palm_Return_Head);\n",
                "  }\n",
                "  Mock.Palm_Return=NULL;\n",
                "  Mock.Palm_Return_Head=NULL;\n",
                "  Mock.Palm_Return_Tail=NULL;\n"
               ]
    returned = @cmock_generator_plugin_expect.mock_destroy(function)
    assert_equal(expected, returned)
  end
  
  should "add mock destroy for functions of style 'int func(uint32 grease)'" do
    function = {:name => "Coconut", :args => [{ :type => "uint32", :name => "grease"}], :return_type => "int" }
    expected = ["  if (Mock.Coconut_Return_Head)\n",
                "  {\n",
                "    free(Mock.Coconut_Return_Head);\n",
                "  }\n",
                "  Mock.Coconut_Return=NULL;\n",
                "  Mock.Coconut_Return_Head=NULL;\n",
                "  Mock.Coconut_Return_Tail=NULL;\n",
                "  if (Mock.Coconut_Expected_grease_Head)\n",
                "  {\n",
                "    free(Mock.Coconut_Expected_grease_Head);\n",
                "  }\n",
                "  Mock.Coconut_Expected_grease=NULL;\n",
                "  Mock.Coconut_Expected_grease_Head=NULL;\n",
                "  Mock.Coconut_Expected_grease_Tail=NULL;\n"
               ]
    returned = @cmock_generator_plugin_expect.mock_destroy(function)
    assert_equal(expected, returned)
  end
  
  should "add mock destroy for functions with strict ordering" do
    function = {:name => "Peach", :args => [], :return_type => "void" }
    expected = [ "  if (Mock.Peach_CallOrder_Head)\n",
                 "  {\n",
                 "    free(Mock.Peach_CallOrder_Head);\n",
                 "  }\n",
                 "  Mock.Peach_CallOrder=NULL;\n",
                 "  Mock.Peach_CallOrder_Head=NULL;\n",
                 "  Mock.Peach_CallOrder_Tail=NULL;\n"
               ]
    returned = @cmock_generator_plugin_expect_strict.mock_destroy(function)
    assert_equal(expected, returned)
  end
end
