# ==========================================
#   CMock Project - Automatic Mock Generation for C
#   Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
#   [Released under MIT License. Please refer to license.txt for details]
# ========================================== 

require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require 'cmock_generator_utils'

class CMockGeneratorUtilsTest < Test::Unit::TestCase
  def setup
    create_mocks :config, :unity_helper, :unity_helper
    
    @config.expect.when_ptr.returns(:compare_ptr)
    @config.expect.enforce_strict_ordering.returns(false)
    @config.expect.plugins.returns([])
    @config.expect.plugins.returns([])
    @config.expect.treat_as.returns(['int','short','long','char','char*'])
    @cmock_generator_utils_simple = CMockGeneratorUtils.new(@config, {:unity_helper => @unity_helper})

    @config.expect.when_ptr.returns(:smart)
    @config.expect.enforce_strict_ordering.returns(true)
    @config.expect.plugins.returns([:array, :cexception])
    @config.expect.plugins.returns([:array, :cexception])
    @config.expect.treat_as.returns(['int','short','long','char','uint32_t','char*'])
    @cmock_generator_utils_complex = CMockGeneratorUtils.new(@config, {:unity_helper => @unity_helper, :A=>1, :B=>2})
  end

  def teardown
  end
  
  should "have set up internal accessors correctly on init" do
    assert_equal(@config, @cmock_generator_utils_simple.config)
    assert_equal({:unity_helper => @unity_helper}, @cmock_generator_utils_simple.helpers)
    assert_equal(false,   @cmock_generator_utils_simple.arrays)
    assert_equal(false,   @cmock_generator_utils_simple.cexception)
  end
  
  should "have set up internal accessors correctly on init, complete with passed helpers" do
    assert_equal(@config, @cmock_generator_utils_complex.config)
    assert_equal({:unity_helper => @unity_helper, :A=>1, :B=>2},@cmock_generator_utils_complex.helpers)
    assert_equal(true, @cmock_generator_utils_complex.arrays)
    assert_equal(true, @cmock_generator_utils_complex.cexception)
  end
  
  should "add code for a base expectation with no plugins" do
    expected =
      "  CMOCK_Apple_CALL_INSTANCE* cmock_call_instance = (CMOCK_Apple_CALL_INSTANCE*)CMock_Guts_MemNew(sizeof(CMOCK_Apple_CALL_INSTANCE));\n" +
      "  UNITY_TEST_ASSERT_NOT_NULL(cmock_call_instance, cmock_line, \"CMock has run out of memory. Please allocate more.\");\n" +
      "  Mock.Apple_CallInstance = (CMOCK_Apple_CALL_INSTANCE*)CMock_Guts_MemChain((void*)Mock.Apple_CallInstance, (void*)cmock_call_instance);\n" +
      "  cmock_call_instance->LineNumber = cmock_line;\n"
    output = @cmock_generator_utils_simple.code_add_base_expectation("Apple")
    assert_equal(expected, output)
  end
        
  should "add code for a base expectation with all plugins" do
    expected =
      "  CMOCK_Apple_CALL_INSTANCE* cmock_call_instance = (CMOCK_Apple_CALL_INSTANCE*)CMock_Guts_MemNew(sizeof(CMOCK_Apple_CALL_INSTANCE));\n" +
      "  UNITY_TEST_ASSERT_NOT_NULL(cmock_call_instance, cmock_line, \"CMock has run out of memory. Please allocate more.\");\n" +
      "  Mock.Apple_CallInstance = (CMOCK_Apple_CALL_INSTANCE*)CMock_Guts_MemChain((void*)Mock.Apple_CallInstance, (void*)cmock_call_instance);\n" +
      "  cmock_call_instance->LineNumber = cmock_line;\n" + 
      "  cmock_call_instance->CallOrder = ++GlobalExpectCount;\n" +
      "  cmock_call_instance->ExceptionToThrow = CEXCEPTION_NONE;\n"
    output = @cmock_generator_utils_complex.code_add_base_expectation("Apple", true)
    assert_equal(expected, output)
  end
        
  should "add code for a base expectation with all plugins and ordering not supported" do
    expected =
      "  CMOCK_Apple_CALL_INSTANCE* cmock_call_instance = (CMOCK_Apple_CALL_INSTANCE*)CMock_Guts_MemNew(sizeof(CMOCK_Apple_CALL_INSTANCE));\n" +
      "  UNITY_TEST_ASSERT_NOT_NULL(cmock_call_instance, cmock_line, \"CMock has run out of memory. Please allocate more.\");\n" +
      "  Mock.Apple_CallInstance = (CMOCK_Apple_CALL_INSTANCE*)CMock_Guts_MemChain((void*)Mock.Apple_CallInstance, (void*)cmock_call_instance);\n" +
      "  cmock_call_instance->LineNumber = cmock_line;\n" +
      "  cmock_call_instance->ExceptionToThrow = CEXCEPTION_NONE;\n"
    output = @cmock_generator_utils_complex.code_add_base_expectation("Apple", false)
    assert_equal(expected, output)
  end
  
  should "add argument expectations for values when no array plugin" do
    arg1 = { :name => "Orange", :const? => false, :type => 'int', :ptr? => false }
    expected1 = "  cmock_call_instance->Expected_Orange = Orange;\n"
    
    arg2 = { :name => "Lemon", :const? => true, :type => 'const char*', :ptr? => true }
    expected2 = "  cmock_call_instance->Expected_Lemon = (const char*)Lemon;\n"
    
    arg3 = { :name => "Kiwi", :const? => false, :type => 'KIWI_T*', :ptr? => true }
    expected3 = "  cmock_call_instance->Expected_Kiwi = Kiwi;\n"
    
    arg4 = { :name => "Lime", :const? => false, :type => 'LIME_T', :ptr? => false }
    expected4 = "  memcpy(&cmock_call_instance->Expected_Lime, &Lime, sizeof(LIME_T));\n" 

    assert_equal(expected1, @cmock_generator_utils_simple.code_add_an_arg_expectation(arg1))
    assert_equal(expected2, @cmock_generator_utils_simple.code_add_an_arg_expectation(arg2))
    assert_equal(expected3, @cmock_generator_utils_simple.code_add_an_arg_expectation(arg3))
    assert_equal(expected4, @cmock_generator_utils_simple.code_add_an_arg_expectation(arg4))
  end
  
  should "add argument expectations for values when array plugin enabled" do
    arg1 = { :name => "Orange", :const? => false, :type => 'int', :ptr? => false }
    expected1 = "  cmock_call_instance->Expected_Orange = Orange;\n"
    
    arg2 = { :name => "Lemon", :const? => true, :type => 'const char*', :ptr? => true }
    expected2 = "  cmock_call_instance->Expected_Lemon = (const char*)Lemon;\n" +
                "  cmock_call_instance->Expected_Lemon_Depth = Lemon_Depth;\n"
    
    arg3 = { :name => "Kiwi", :const? => false, :type => 'KIWI_T*', :ptr? => true }
    expected3 = "  cmock_call_instance->Expected_Kiwi = Kiwi;\n" +
                "  cmock_call_instance->Expected_Kiwi_Depth = Kiwi_Depth;\n"
    
    arg4 = { :name => "Lime", :const? => false, :type => 'LIME_T', :ptr? => false }
    expected4 = "  memcpy(&cmock_call_instance->Expected_Lime, &Lime, sizeof(LIME_T));\n" 

    assert_equal(expected1, @cmock_generator_utils_complex.code_add_an_arg_expectation(arg1))
    assert_equal(expected2, @cmock_generator_utils_complex.code_add_an_arg_expectation(arg2, 'Lemon_Depth'))
    assert_equal(expected3, @cmock_generator_utils_complex.code_add_an_arg_expectation(arg3, 'Lemon_Depth'))
    assert_equal(expected4, @cmock_generator_utils_complex.code_add_an_arg_expectation(arg4))
  end
  
  should 'not have an argument loader when the function has no arguments' do
    function = { :name => "Melon", :args_string => "void" }
     
    assert_equal("", @cmock_generator_utils_complex.code_add_argument_loader(function))
  end
  
  should 'create an argument loader when the function has arguments' do
    function = { :name => "Melon", 
                 :args_string => "stuff",
                 :args => [test_arg[:int_ptr], test_arg[:mytype], test_arg[:string]]
    }
    expected = "void CMockExpectParameters_Melon(CMOCK_Melon_CALL_INSTANCE* cmock_call_instance, stuff)\n{\n" + 
               "  cmock_call_instance->Expected_MyIntPtr = MyIntPtr;\n" +
               "  memcpy(&cmock_call_instance->Expected_MyMyType, &MyMyType, sizeof(MY_TYPE));\n" +
               "  cmock_call_instance->Expected_MyStr = (char*)MyStr;\n" +
               "}\n\n"
    assert_equal(expected, @cmock_generator_utils_simple.code_add_argument_loader(function))
  end

  should 'create an argument loader when the function has arguments supporting arrays' do
    function = { :name => "Melon", 
                 :args_string => "stuff",
                 :args => [test_arg[:int_ptr], test_arg[:mytype], test_arg[:string]]
    }
    expected = "void CMockExpectParameters_Melon(CMOCK_Melon_CALL_INSTANCE* cmock_call_instance, int* MyIntPtr, int MyIntPtr_Depth, const MY_TYPE MyMyType, const char* MyStr)\n{\n" + 
               "  cmock_call_instance->Expected_MyIntPtr = MyIntPtr;\n" +
               "  cmock_call_instance->Expected_MyIntPtr_Depth = MyIntPtr_Depth;\n" +
               "  memcpy(&cmock_call_instance->Expected_MyMyType, &MyMyType, sizeof(MY_TYPE));\n" +
               "  cmock_call_instance->Expected_MyStr = (char*)MyStr;\n" +
               "}\n\n"
    assert_equal(expected, @cmock_generator_utils_complex.code_add_argument_loader(function))
  end
  
  should "not call argument loader if there are no arguments to actually use for this function" do
    function = { :name => "Pineapple", :args_string => "void" }
     
    assert_equal("", @cmock_generator_utils_complex.code_call_argument_loader(function))
  end

  should 'call an argument loader when the function has arguments' do
    function = { :name => "Pineapple", 
                 :args_string => "stuff",
                 :args => [test_arg[:int_ptr], test_arg[:mytype], test_arg[:string]]
    }
    expected = "  CMockExpectParameters_Pineapple(cmock_call_instance, MyIntPtr, MyMyType, MyStr);\n"
    assert_equal(expected, @cmock_generator_utils_simple.code_call_argument_loader(function))
  end

  should 'call an argument loader when the function has arguments with arrays' do
    function = { :name => "Pineapple", 
                 :args_string => "stuff",
                 :args => [test_arg[:int_ptr], test_arg[:mytype], test_arg[:string]]
    }
    expected = "  CMockExpectParameters_Pineapple(cmock_call_instance, MyIntPtr, 1, MyMyType, MyStr);\n"
    assert_equal(expected, @cmock_generator_utils_complex.code_call_argument_loader(function))
  end
  
  should 'handle a simple assert when requested' do
    function = { :name => 'Pear' }
    arg      = test_arg[:int]
    expected = "  UNITY_TEST_ASSERT_EQUAL_INT(cmock_call_instance->Expected_MyInt, MyInt, cmock_line, \"Function 'Pear' called with unexpected value for argument 'MyInt'.\");\n"
    @unity_helper.expect.get_helper('int').returns(['UNITY_TEST_ASSERT_EQUAL_INT',''])
    assert_equal(expected, @cmock_generator_utils_simple.code_verify_an_arg_expectation(function, arg))
  end

  should 'handle a pointer comparison when configured to do so' do
    function = { :name => 'Pear' }
    arg      = test_arg[:int_ptr]
    expected = "  UNITY_TEST_ASSERT_EQUAL_PTR(cmock_call_instance->Expected_MyIntPtr, MyIntPtr, cmock_line, \"Function 'Pear' called with unexpected value for argument 'MyIntPtr'.\");\n"
    assert_equal(expected, @cmock_generator_utils_simple.code_verify_an_arg_expectation(function, arg))
  end

  should 'handle const char as string compares ' do
    function = { :name => 'Pear' }
    arg      = test_arg[:string]
    expected = "  UNITY_TEST_ASSERT_EQUAL_STRING(cmock_call_instance->Expected_MyStr, MyStr, cmock_line, \"Function 'Pear' called with unexpected value for argument 'MyStr'.\");\n"
    @unity_helper.expect.get_helper('char*').returns(['UNITY_TEST_ASSERT_EQUAL_STRING',''])
    assert_equal(expected, @cmock_generator_utils_simple.code_verify_an_arg_expectation(function, arg))
  end
  
  should 'handle custom types as memory compares when we have no better way to do it' do
    function = { :name => 'Pear' }
    arg      = test_arg[:mytype]
    expected = "  UNITY_TEST_ASSERT_EQUAL_MEMORY((void*)(&cmock_call_instance->Expected_MyMyType), (void*)(&MyMyType), sizeof(MY_TYPE), cmock_line, \"Function 'Pear' called with unexpected value for argument 'MyMyType'.\");\n"
    @unity_helper.expect.get_helper('MY_TYPE').returns(['UNITY_TEST_ASSERT_EQUAL_MEMORY','&'])
    assert_equal(expected, @cmock_generator_utils_simple.code_verify_an_arg_expectation(function, arg))
  end

  should 'handle custom types with custom handlers when available, even if they do not support the extra message' do
    function = { :name => 'Pear' }
    arg      = test_arg[:mytype]
    expected = "  UNITY_TEST_ASSERT_EQUAL_MY_TYPE(cmock_call_instance->Expected_MyMyType, MyMyType, cmock_line, \"Function 'Pear' called with unexpected value for argument 'MyMyType'.\");\n"
    @unity_helper.expect.get_helper('MY_TYPE').returns(['UNITY_TEST_ASSERT_EQUAL_MY_TYPE',''])
    assert_equal(expected, @cmock_generator_utils_simple.code_verify_an_arg_expectation(function, arg))
  end
  
  should 'handle pointers to custom types with array handlers, even if the array extension is turned off' do
    function = { :name => 'Pear' }
    arg      = test_arg[:mytype]
    expected = "  UNITY_TEST_ASSERT_EQUAL_MY_TYPE_ARRAY(&cmock_call_instance->Expected_MyMyType, &MyMyType, 1, cmock_line, \"Function 'Pear' called with unexpected value for argument 'MyMyType'.\");\n"
    @unity_helper.expect.get_helper('MY_TYPE').returns(['UNITY_TEST_ASSERT_EQUAL_MY_TYPE_ARRAY','&'])
    assert_equal(expected, @cmock_generator_utils_simple.code_verify_an_arg_expectation(function, arg))
  end

  should 'handle a simple assert when requested with array plugin enabled' do
    function = { :name => 'Pear' }
    arg      = test_arg[:int]
    expected = "  UNITY_TEST_ASSERT_EQUAL_INT(cmock_call_instance->Expected_MyInt, MyInt, cmock_line, \"Function 'Pear' called with unexpected value for argument 'MyInt'.\");\n"
    @unity_helper.expect.get_helper('int').returns(['UNITY_TEST_ASSERT_EQUAL_INT',''])
    assert_equal(expected, @cmock_generator_utils_complex.code_verify_an_arg_expectation(function, arg))
  end
  
  should 'handle an array comparison with array plugin enabled' do
    function = { :name => 'Pear' }
    arg      = test_arg[:int_ptr]
    expected = "  if (cmock_call_instance->Expected_MyIntPtr == NULL)\n" +
               "    { UNITY_TEST_ASSERT_NULL(MyIntPtr, cmock_line, \"Expected NULL. Function 'Pear' called with unexpected value for argument 'MyIntPtr'.\"); }\n" +
               "  else if (cmock_call_instance->Expected_MyIntPtr_Depth == 0)\n" +
               "    { UNITY_TEST_ASSERT_EQUAL_PTR(cmock_call_instance->Expected_MyIntPtr, MyIntPtr, cmock_line, \"Function 'Pear' called with unexpected value for argument 'MyIntPtr'.\"); }\n" +
               "  else\n" +
               "    { UNITY_TEST_ASSERT_EQUAL_INT_ARRAY(cmock_call_instance->Expected_MyIntPtr, MyIntPtr, cmock_call_instance->Expected_MyIntPtr_Depth, cmock_line, \"Function 'Pear' called with unexpected value for argument 'MyIntPtr'.\"); }\n"
    @unity_helper.expect.get_helper('int*').returns(['UNITY_TEST_ASSERT_EQUAL_INT_ARRAY',''])
   assert_equal(expected, @cmock_generator_utils_complex.code_verify_an_arg_expectation(function, arg))
  end
  
  should 'handle const char as string compares with array plugin enabled' do
    function = { :name => 'Pear' }
    arg      = test_arg[:string]
    expected = "  UNITY_TEST_ASSERT_EQUAL_STRING(cmock_call_instance->Expected_MyStr, MyStr, cmock_line, \"Function 'Pear' called with unexpected value for argument 'MyStr'.\");\n"
    @unity_helper.expect.get_helper('char*').returns(['UNITY_TEST_ASSERT_EQUAL_STRING',''])
    assert_equal(expected, @cmock_generator_utils_complex.code_verify_an_arg_expectation(function, arg))
  end
  
  should 'handle custom types as memory compares when we have no better way to do it with array plugin enabled' do
    function = { :name => 'Pear' }
    arg      = test_arg[:mytype]
    expected = "  UNITY_TEST_ASSERT_EQUAL_MEMORY((void*)(&cmock_call_instance->Expected_MyMyType), (void*)(&MyMyType), sizeof(MY_TYPE), cmock_line, \"Function 'Pear' called with unexpected value for argument 'MyMyType'.\");\n"
    @unity_helper.expect.get_helper('MY_TYPE').returns(['UNITY_TEST_ASSERT_EQUAL_MEMORY','&'])
    assert_equal(expected, @cmock_generator_utils_complex.code_verify_an_arg_expectation(function, arg))
  end
  
  should 'handle custom types with custom handlers when available, even if they do not support the extra message with array plugin enabled' do
    function = { :name => 'Pear' }
    arg      = test_arg[:mytype]
    expected = "  UNITY_TEST_ASSERT_EQUAL_MY_TYPE(cmock_call_instance->Expected_MyMyType, MyMyType, cmock_line, \"Function 'Pear' called with unexpected value for argument 'MyMyType'.\");\n"
    @unity_helper.expect.get_helper('MY_TYPE').returns(['UNITY_TEST_ASSERT_EQUAL_MY_TYPE',''])
    assert_equal(expected, @cmock_generator_utils_complex.code_verify_an_arg_expectation(function, arg))
  end

  should 'handle custom types with array handlers when array plugin is enabled' do
    function = { :name => 'Pear' }
    arg      = test_arg[:mytype_ptr]
    expected = "  if (cmock_call_instance->Expected_MyMyTypePtr == NULL)\n" +
               "    { UNITY_TEST_ASSERT_NULL(MyMyTypePtr, cmock_line, \"Expected NULL. Function 'Pear' called with unexpected value for argument 'MyMyTypePtr'.\"); }\n" +
               "  else if (cmock_call_instance->Expected_MyMyTypePtr_Depth == 0)\n" +
               "    { UNITY_TEST_ASSERT_EQUAL_PTR(cmock_call_instance->Expected_MyMyTypePtr, MyMyTypePtr, cmock_line, \"Function 'Pear' called with unexpected value for argument 'MyMyTypePtr'.\"); }\n" +
               "  else\n" +
               "    { UNITY_TEST_ASSERT_EQUAL_MY_TYPE_ARRAY(cmock_call_instance->Expected_MyMyTypePtr, MyMyTypePtr, cmock_call_instance->Expected_MyMyTypePtr_Depth, cmock_line, \"Function 'Pear' called with unexpected value for argument 'MyMyTypePtr'.\"); }\n"
    @unity_helper.expect.get_helper('MY_TYPE*').returns(['UNITY_TEST_ASSERT_EQUAL_MY_TYPE_ARRAY',''])
    assert_equal(expected, @cmock_generator_utils_complex.code_verify_an_arg_expectation(function, arg))
  end
  
  should 'handle custom types with array handlers when array plugin is enabled for non-array types' do
    function = { :name => 'Pear' }
    arg      = test_arg[:mytype]
    expected = "  UNITY_TEST_ASSERT_EQUAL_MY_TYPE_ARRAY(&cmock_call_instance->Expected_MyMyType, &MyMyType, 1, cmock_line, \"Function 'Pear' called with unexpected value for argument 'MyMyType'.\");\n"
    @unity_helper.expect.get_helper('MY_TYPE').returns(['UNITY_TEST_ASSERT_EQUAL_MY_TYPE_ARRAY','&'])
    assert_equal(expected, @cmock_generator_utils_complex.code_verify_an_arg_expectation(function, arg))
  end
end
