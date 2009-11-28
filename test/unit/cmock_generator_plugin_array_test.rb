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
  end
  
  should "not include any additional include files" do 
    assert(!@cmock_generator_plugin_array.respond_to?(:include_files))
  end
  
  should "not add to control structure for functions of style 'int* func(void)'" do
    function = {:name => "Oak", :args => [], :return_type => "int*"}
    returned = @cmock_generator_plugin_array.instance_structure(function)
    assert_equal("", returned)
  end
  
  should "add to control structure mock needs of functions of style 'void func(int chicken, int* pork)'" do
    function = {:name => "Cedar", :args => [{ :name => "chicken", :type => "int", :ptr? => false}, { :name => "pork", :type => "int*", :ptr? => true}], :return_type => "void"}
    expected = ["\n",
                "  int* Cedar_Expected_pork_Depth;\n",
                "  int* Cedar_Expected_pork_Depth_Head;\n",
                "  int* Cedar_Expected_pork_Depth_Tail;\n"
               ].join
    returned = @cmock_generator_plugin_array.instance_structure(function)
    assert_equal(expected, returned)
  end
  
  should "not add an additional mock interface for functions not containing pointers" do
    function = {:name => "Maple", :args_string => "int blah", :return_type => "char*", :contains_ptr? => false}
    returned = @cmock_generator_plugin_array.mock_function_declarations(function)
    assert_nil(returned)
  end
  
  should "add another mock function declaration for functions of style 'void func(int* tofu)'" do
    function = {:name => "Pine", 
                :args => [{ :type => "int*",
                           :name => "tofu",
                           :ptr? => true,
                         }],
                :return_type => "void",
                :return_string => "void", 
                :contains_ptr? => true }
    
    expected = "void #{function[:name]}_ExpectWithArray(int* tofu, int tofu_Depth);\n"
    returned = @cmock_generator_plugin_array.mock_function_declarations(function)
    assert_equal(expected, returned)
  end
  
  should "add another mock function declaration for functions of style 'const char* func(int* tofu)'" do
    function = {:name => "Pine", 
                :args => [{ :type => "int*",
                           :name => "tofu",
                           :ptr? => true,
                         }],
                :return_type => "const char*", 
                :return_string => "const char* toReturn",
                :contains_ptr? => true }
    
    expected = "void #{function[:name]}_ExpectWithArrayAndReturn(int* tofu, int tofu_Depth, const char* toReturn);\n"
    returned = @cmock_generator_plugin_array.mock_function_declarations(function)
    assert_equal(expected, returned)
  end
    
  should "not require anything for implementation prefix" do
    assert(!@cmock_generator_plugin_array.respond_to?(:mock_implementation_prefix))
  end
  
  should "not have a mock function implementation for functions of style 'int* func(void)'" do
    function = {:name => "Apple", :args => [], :return_type => "int*", :contains_ptr? => false}
    returned = @cmock_generator_plugin_array.mock_implementation(function)
    assert_nil(returned)
  end
  
  should "not have a mock function implementation for functions containing pointers either (handled in expect)" do
    function = {:name => "Apple", :args => [{ :type => 'int*', :name => 'sausage', :ptr? => true}], :return_type => "int*", :contains_ptr? => true}
    returned = @cmock_generator_plugin_array.mock_implementation(function)
    assert_nil(returned)
  end

  should "not have a mock interfaces for functions of style 'int* func(void)'" do
    function = {:name => "Pear", :args => [], :args_string => "void", :return_type => "int*"}
    returned = @cmock_generator_plugin_array.mock_interfaces(function)
    assert_nil(returned)
  end
  
  should "add mock interfaces for functions of style 'int func(int* pescado, int pes)'" do
    function = {:name => "Lemon", 
                :args => [{ :type => "int*", :name => "pescado", :ptr? => true}, { :type => "int", :name => "pes", :ptr? => false}], 
                :args_string => "int* pescado, int pes", 
                :return_type => "int", 
                :return_string => "int toReturn", 
                :contains_ptr? => true }
    @utils.expect.code_add_an_arg_expectation(function, function[:args][0], "pescado_Depth").returns("mock_retval_2")
    @utils.expect.code_add_an_arg_expectation(function, function[:args][1], "1").returns("mock_retval_3")
    @utils.expect.code_add_base_expectation("Lemon").returns("mock_retval_0")
    @utils.expect.code_insert_item_into_expect_array(function[:return_type], "Mock.Lemon_Return", 'toReturn').returns("mock_retval_1")
    
    expected = ["void ExpectParametersWithArray_Lemon(int* pescado, int pescado_Depth, int pes)\n",
                "{\n",
                "mock_retval_2",
                "mock_retval_3",
                "}\n\n",
                "void Lemon_ExpectWithArrayAndReturn(int* pescado, int pescado_Depth, int pes, int toReturn)\n",
                "{\n",
                "mock_retval_0",
                "  ExpectParametersWithArray_Lemon(pescado, pescado_Depth, pes);\n",
                "mock_retval_1",
                "  Mock.Lemon_Return = Mock.Lemon_Return_Head;\n",
                "  Mock.Lemon_Return += Mock.Lemon_CallCount;\n",
                "}\n\n"
               ].join
    returned = @cmock_generator_plugin_array.mock_interfaces(function).join
    assert_equal(expected, returned)
  end
  
  should "only add destruction of Depth attributes" do
    function = {:name => "Coconut", 
                :args => [ { :type => "uint32*", :name => "grease", :ptr? => true},
                           { :type => "uint16",  :name => "grime",  :ptr? => false}], 
                :return_type => "int",
                :contains_ptr? => true }
    expected = [ %q[
  if (Mock.Coconut_Expected_grease_Depth_Head)
  {
    free(Mock.Coconut_Expected_grease_Depth_Head);
  }
  Mock.Coconut_Expected_grease_Depth=NULL;
  Mock.Coconut_Expected_grease_Depth_Head=NULL;
  Mock.Coconut_Expected_grease_Depth_Tail=NULL;
] ]
    returned = @cmock_generator_plugin_array.mock_destroy(function)
    assert_equal(expected, returned)
  end
  
end
