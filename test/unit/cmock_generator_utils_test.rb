require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require 'cmock_generator_utils'

class CMockGeneratorUtilsTest < Test::Unit::TestCase
  def setup
    create_mocks :config, :unity_helper
    @config.expect.when_ptr_star.returns(:compare_data)
    @config.expect.enforce_strict_ordering.returns(false)
    @cmock_generator_utils = CMockGeneratorUtils.new(@config)
  end

  def teardown
  end
  
  should "have set up internal accessors correctly on init" do
    assert_equal(@config, @cmock_generator_utils.config)
    assert_equal({},      @cmock_generator_utils.helpers)
  end
  
  should "have set up internal accessors correctly on init, complete with passed helpers" do
    create_mocks :config
    @config.expect.when_ptr_star.returns(:compare_ptr)
    @config.expect.enforce_strict_ordering.returns(false)
    @cmock_generator_utils = CMockGeneratorUtils.new(@config, {:A=>1, :B=>2})
    assert_equal(@config, @cmock_generator_utils.config)
    assert_equal({:A=>1, :B=>2},@cmock_generator_utils.helpers)
  end
  
  should "set up an empty call list if no arguments passed" do
    function = {:args => []}
    expected = ""
    returned = @cmock_generator_utils.create_call_list(function)
    assert_equal(expected, returned)
  end
  
  should "set up a single call list if one arguments passed" do
    function = {:args => [{ :type => "const char*", :name => "spoon"}]}
    expected = "spoon"
    returned = @cmock_generator_utils.create_call_list(function)
    assert_equal(expected, returned)
  end
  
  should "set up a call list if multiple arguments passed" do
    function = {:args => [{ :type => "const char*", :name => "spoon"}, { :type => "int", :name => "fork"}, { :type => "unsigned int", :name => "knife"}] }
    expected = "spoon, fork, knife"
    returned = @cmock_generator_utils.create_call_list(function)
    assert_equal(expected, returned)
  end
  
  should "make expand array" do
    the_type = "int"
    the_array = "array"
    new_value = "new_value"
    
    expected = ["\n",
                "  {\n",
                "    int sz = 0;\n",
                "    int *pointer = array_Head;\n",
                "    while (pointer && pointer != array_Tail) { sz++; pointer++; }\n",
                "    if (sz == 0)\n",
                "    {\n",
                "      array_Head = (int*)malloc(2*sizeof(int));\n",
                "      if (!array_Head)\n",
                "        Mock.allocFailure++;\n",
                "    }\n",
                "    else\n",
                "    {\n",
                "      int *ptmp = (int*)realloc(array_Head, sizeof(int) * (sz+1));\n",
                "      if (!ptmp)\n",
                "        Mock.allocFailure++;\n",
                "      else\n",
                "        array_Head = ptmp;\n","    }\n",
                "    memcpy(&array_Head[sz], &new_value, sizeof(int));\n",
                "    array_Tail = &array_Head[sz+1];\n",
                "  }\n"
               ].join
    returned = @cmock_generator_utils.code_insert_item_into_expect_array(the_type, the_array, new_value)
    assert_equal(expected, returned)
  end
  
  should "make handle return" do 
    function = { :name => "Spatula", :return_type => "uint64"}
    expected = ["\n",
                "  if (Mock.Spatula_Return != Mock.Spatula_Return_Tail)\n",
                "  {\n",
                "    uint64 toReturn = *Mock.Spatula_Return;\n",
                "    Mock.Spatula_Return++;\n",
                "    return toReturn;\n",
                "  }\n",
                "  else\n",
                "  {\n",
                "    return *(Mock.Spatula_Return_Tail - 1);\n",
                "  }\n"
               ].join
    returned = @cmock_generator_utils.code_handle_return_value(function)
    assert_equal(expected, returned)
  end
  
  should "add new expected handler" do
    function = { :name => "PizzaCutter", :return_type => "uint64"}
    var_type = "uint16"
    var_name = "Spork"
    
    expected = ["\n",
                "  {\n",
                "    int sz = 0;\n",
                "    uint16 *pointer = Mock.PizzaCutter_Expected_Spork_Head;\n",
                "    while (pointer && pointer != Mock.PizzaCutter_Expected_Spork_Tail) { sz++; pointer++; }\n",
                "    if (sz == 0)\n",
                "    {\n",
                "      Mock.PizzaCutter_Expected_Spork_Head = (uint16*)malloc(2*sizeof(uint16));\n",
                "      if (!Mock.PizzaCutter_Expected_Spork_Head)\n",
                "        Mock.allocFailure++;\n",
                "    }\n",
                "    else\n",
                "    {\n",
                "      uint16 *ptmp = (uint16*)realloc(Mock.PizzaCutter_Expected_Spork_Head, sizeof(uint16) * (sz+1));\n",
                "      if (!ptmp)\n",
                "        Mock.allocFailure++;\n",
                "      else\n",
                "        Mock.PizzaCutter_Expected_Spork_Head = ptmp;\n",
                "    }\n",
                "    memcpy(&Mock.PizzaCutter_Expected_Spork_Head[sz], &Spork, sizeof(uint16));\n",
                "    Mock.PizzaCutter_Expected_Spork_Tail = &Mock.PizzaCutter_Expected_Spork_Head[sz+1];\n",
                "  }\n",
                "  Mock.PizzaCutter_Expected_Spork = Mock.PizzaCutter_Expected_Spork_Head;\n",
                "  Mock.PizzaCutter_Expected_Spork += Mock.PizzaCutter_CallCount;\n"
               ].join
    returned = @cmock_generator_utils.code_add_an_arg_expectation(function, var_type, var_name)
    assert_equal(expected, returned)
  end
  
  should "add base expectations, with nothing else when strict ordering not turned on" do
    expected = "  Mock.Nectarine_CallsExpected++;\n"
    returned = @cmock_generator_utils.code_add_base_expectation("Nectarine")
    
    assert_equal(expected, returned)
  end

  should "add base expectations, with stuff for strict ordering turned on" do
    expected = ["  Mock.Nectarine_CallsExpected++;\n",
                "  ++GlobalExpectCount;\n",
                "\n",
                "  {\n",
                "    int sz = 0;\n",
                "    int *pointer = Mock.Nectarine_CallOrder_Head;\n",
                "    while (pointer && pointer != Mock.Nectarine_CallOrder_Tail) { sz++; pointer++; }\n",
                "    if (sz == 0)\n",
                "    {\n",
                "      Mock.Nectarine_CallOrder_Head = (int*)malloc(2*sizeof(int));\n",
                "      if (!Mock.Nectarine_CallOrder_Head)\n",
                "        Mock.allocFailure++;\n",
                "    }\n",
                "    else\n",
                "    {\n",
                "      int *ptmp = (int*)realloc(Mock.Nectarine_CallOrder_Head, sizeof(int) * (sz+1));\n",
                "      if (!ptmp)\n",
                "        Mock.allocFailure++;\n",
                "      else\n",
                "        Mock.Nectarine_CallOrder_Head = ptmp;\n",
                "    }\n",
                "    memcpy(&Mock.Nectarine_CallOrder_Head[sz], &GlobalExpectCount, sizeof(int));\n",
                "    Mock.Nectarine_CallOrder_Tail = &Mock.Nectarine_CallOrder_Head[sz+1];\n",
                "  }\n",
                "  Mock.Nectarine_CallOrder = Mock.Nectarine_CallOrder_Head;\n",
                "  Mock.Nectarine_CallOrder += Mock.Nectarine_CallCount;\n" ].join
    @cmock_generator_utils.ordered = true
    returned = @cmock_generator_utils.code_add_base_expectation("Nectarine")
    assert_equal(expected, returned)
  end
  
  should "make handle expected when no helpers are available" do
    function = { :name => "CanOpener", :return_type => "uint64"}
    var_type = "uint16"
    var_name = "CorkScrew"
    
    expected = ["\n",
                "  if (Mock.CanOpener_Expected_CorkScrew != Mock.CanOpener_Expected_CorkScrew_Tail)\n",
                "  {\n",
                "    uint16* p_expected = Mock.CanOpener_Expected_CorkScrew;\n",
                "    Mock.CanOpener_Expected_CorkScrew++;\n",
                "    TEST_ASSERT_EQUAL_MESSAGE(*p_expected, CorkScrew, \"Function 'CanOpener' called with unexpected value for argument 'CorkScrew'.\");\n",
                "  }\n"
               ].join
    returned = @cmock_generator_utils.code_verify_an_arg_expectation(function, var_type, var_name)
    assert_equal(expected, returned)
  end

  should "make handle expected for character strings" do
    function = { :name => "MeasureCup", :return_type => "uint64"}
    var_type = "const char*"
    var_name = "TeaSpoon"
    
    @cmock_generator_utils.helpers = {:unity_helper => @unity_helper}
    @unity_helper.expect.get_helper(var_type).returns("TEST_ASSERT_EQUAL_STRING_MESSAGE")
    
    expected = ["\n",
                "  if (Mock.MeasureCup_Expected_TeaSpoon != Mock.MeasureCup_Expected_TeaSpoon_Tail)\n",
                "  {\n",
                "    const char** p_expected = Mock.MeasureCup_Expected_TeaSpoon;\n",
                "    Mock.MeasureCup_Expected_TeaSpoon++;\n",
                "    TEST_ASSERT_EQUAL_STRING_MESSAGE(*p_expected, TeaSpoon, \"Function 'MeasureCup' called with unexpected value for argument 'TeaSpoon'.\");\n",
                "  }\n"
               ].join
    returned = @cmock_generator_utils.code_verify_an_arg_expectation(function, var_type, var_name)
    assert_equal(expected, returned)
  end
  
  should "make handle expected for custom types from unity helper" do
    function = { :name => "TeaPot", :return_type => "uint64"}
    var_type = "MANDELBROT_SET_T"
    var_name = "TeaSpoon"
    
    @cmock_generator_utils.helpers = {:unity_helper => @unity_helper}
    @unity_helper.expect.get_helper(var_type).returns("TEST_ASSERT_EQUAL_MANDELBROT_SET_T_MESSAGE")
    
    expected = ["\n",
                "  if (Mock.TeaPot_Expected_TeaSpoon != Mock.TeaPot_Expected_TeaSpoon_Tail)\n",
                "  {\n",
                "    MANDELBROT_SET_T* p_expected = Mock.TeaPot_Expected_TeaSpoon;\n",
                "    Mock.TeaPot_Expected_TeaSpoon++;\n",
                "    TEST_ASSERT_EQUAL_MANDELBROT_SET_T_MESSAGE(*p_expected, TeaSpoon, \"Function 'TeaPot' called with unexpected value for argument 'TeaSpoon'.\");\n",
                "  }\n"
               ].join
    returned = @cmock_generator_utils.code_verify_an_arg_expectation(function, var_type, var_name)
    assert_equal(expected, returned)
  end

  should "make handle default types with memory compares, which involves extra work" do
    function = { :name => "Toaster", :return_type => "uint64"}
    var_type = "SOME_STRUCT"
    var_name = "Bread"
    
    @cmock_generator_utils.helpers = {:unity_helper => @unity_helper}
    @unity_helper.expect.get_helper(var_type).returns("TEST_ASSERT_EQUAL_MEMORY_MESSAGE")
    
    expected = ["\n",
                "  if (Mock.Toaster_Expected_Bread != Mock.Toaster_Expected_Bread_Tail)\n",
                "  {\n",
                "    SOME_STRUCT* p_expected = Mock.Toaster_Expected_Bread;\n",
                "    Mock.Toaster_Expected_Bread++;\n",
                "    TEST_ASSERT_EQUAL_MEMORY_MESSAGE((void*)p_expected, (void*)&(Bread), sizeof(SOME_STRUCT), \"Function 'Toaster' called with unexpected value for argument 'Bread'.\");\n",
                "  }\n"
               ].join
    returned = @cmock_generator_utils.code_verify_an_arg_expectation(function, var_type, var_name)
    assert_equal(expected, returned)
  end
  
  should "make handle default types with array compares, which involves extra work" do
    function = { :name => "Blender", :return_type => "uint16*"}
    var_type = "FRUIT*"
    var_name = "Strawberry"
    
    @cmock_generator_utils.helpers = {:unity_helper => @unity_helper}
    @unity_helper.expect.get_helper(var_type).returns("TEST_ASSERT_EQUAL_FRUIT_ARRAY_MESSAGE")
    
    expected = ["\n",
                "  if (Mock.Blender_Expected_Strawberry != Mock.Blender_Expected_Strawberry_Tail)\n",
                "  {\n",
                "    FRUIT** p_expected = Mock.Blender_Expected_Strawberry;\n",
                "    Mock.Blender_Expected_Strawberry++;\n",
                "    if (*p_expected == NULL)\n",
                "      { TEST_ASSERT_NULL(Strawberry); }\n",
                "    else\n",
                "      { TEST_ASSERT_EQUAL_FRUIT_ARRAY_MESSAGE(*p_expected, Strawberry, 1, \"Function 'Blender' called with unexpected value for argument 'Strawberry'.\"); }\n",
                "  }\n"
               ].join
    returned = @cmock_generator_utils.code_verify_an_arg_expectation(function, var_type, var_name)
    assert_equal(expected, returned)
  end
end
