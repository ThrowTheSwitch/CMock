# ==========================================
#   CMock Project - Automatic Mock Generation for C
#   Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
#   [Released under MIT License. Please refer to license.txt for details]
# ========================================== 

require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require 'cmock_generator_plugin_return_thru_ptr'

class CMockGeneratorPluginReturnThruPtrTest < Test::Unit::TestCase
  def setup
    create_mocks :config, :utils

    # int *Oak(void)"
    @void_func = {:name => "Oak", :args => [], :return => test_return[:int_ptr]}

    # char *Maple(int blah)
    @simple_func = {:name => "Maple",
                    :args => [{:name => "blah", :type => "int", :ptr? => false}],
                    :return  => test_return[:string],
                    :contains_ptr? => false}

    # void Pine(int chicken, const int beef, int *tofu)
    @complex_func = {:name => "Pine", 
                     :args => [{ :type => "int",
                                 :name => "chicken",
                                 :ptr? => false,
                               },
                               { :type => "int*",
                                 :name => "beef",
                                 :ptr? => true,
                                 :const? => true,
                               },
                               { :type => "int*",
                                 :name => "tofu",
                                 :ptr? => true,
                               }],
                     :return => test_return[:void], 
                     :contains_ptr? => true }

    #no strict ordering
    @cmock_generator_plugin_return_thru_ptr = CMockGeneratorPluginReturnThruPtr.new(@config, @utils)
  end

  def teardown
  end

  def simple_func_expect
    @utils.expect.ptr_or_str?('int').returns(false)
  end

  def complex_func_expect
    @utils.expect.ptr_or_str?('int').returns(false)
    @utils.expect.ptr_or_str?('int*').returns(true)
    @utils.expect.ptr_or_str?('int*').returns(true)
  end
  
  should "have set up internal accessors correctly on init" do
    assert_equal(@utils,  @cmock_generator_plugin_return_thru_ptr.utils)
    assert_equal(9,       @cmock_generator_plugin_return_thru_ptr.priority)
  end
  
  should "not include any additional include files" do 
    assert(!@cmock_generator_plugin_return_thru_ptr.respond_to?(:include_files))
  end

  should "not add to typedef structure for functions of style 'int* func(void)'" do
    returned = @cmock_generator_plugin_return_thru_ptr.instance_typedefs(@void_func)
    assert_equal("", returned)
  end
  
  should "add to tyepdef structure mock needs of functions of style 'void func(int chicken, int* pork)'" do
    complex_func_expect()
    expected = "  int ReturnThruPtr_tofu_Used;\n" +
               "  int* ReturnThruPtr_tofu_Val;\n" +
               "  int ReturnThruPtr_tofu_Size;\n"
    returned = @cmock_generator_plugin_return_thru_ptr.instance_typedefs(@complex_func)
    assert_equal(expected, returned)
  end

  should "not add an additional mock interface for functions not containing pointers" do
    simple_func_expect()
    returned = @cmock_generator_plugin_return_thru_ptr.mock_function_declarations(@simple_func)
    assert_equal("", returned)
  end

  should "add a mock function declaration only for non-const pointer arguments" do
    complex_func_expect();
    
    expected =
      "#define Pine_ReturnThruPtr_tofu(tofu)" +
      " Pine_CMockReturnMemThruPtr_tofu(__LINE__, tofu, sizeof(*tofu))\n" +
      "#define Pine_ReturnArrayThruPtr_tofu(tofu, cmock_len)" +
      " Pine_CMockReturnMemThruPtr_tofu(__LINE__, tofu, cmock_len * sizeof(*tofu))\n" +
      "#define Pine_ReturnMemThruPtr_tofu(tofu, cmock_size)" +
      " Pine_CMockReturnMemThruPtr_tofu(__LINE__, tofu, cmock_size)\n" +
      "void Pine_CMockReturnMemThruPtr_tofu(UNITY_LINE_TYPE cmock_line, int* tofu, int cmock_size);\n"

    returned = @cmock_generator_plugin_return_thru_ptr.mock_function_declarations(@complex_func)
    assert_equal(expected, returned)
  end

  should "add mock interfaces only for non-const pointer arguments" do
    complex_func_expect();

    expected =
      "void Pine_CMockReturnMemThruPtr_tofu(UNITY_LINE_TYPE cmock_line, int* tofu, int cmock_size)\n" +
      "{\n" +
      "  CMOCK_Pine_CALL_INSTANCE* cmock_call_instance = " +
      "cmock_call_instance = (CMOCK_Pine_CALL_INSTANCE*)CMock_Guts_GetAddressFor(CMock_Guts_MemEndOfChain(Mock.Pine_CallInstance));\n" +
      "  UNITY_TEST_ASSERT_NOT_NULL(cmock_call_instance, cmock_line, \"tofu ReturnThruPtr called before Expect on 'Pine'.\");\n" +
      "  cmock_call_instance->ReturnThruPtr_tofu_Used = 1;\n" +
      "  cmock_call_instance->ReturnThruPtr_tofu_Val = tofu;\n" +
      "  cmock_call_instance->ReturnThruPtr_tofu_Size = cmock_size;\n" +
      "}\n\n"

    returned = @cmock_generator_plugin_return_thru_ptr.mock_interfaces(@complex_func).join("")
    assert_equal(expected, returned)
  end

  should "add mock implementations only for non-const pointer arguments" do
    complex_func_expect()

    expected =
      "  if (cmock_call_instance->ReturnThruPtr_tofu_Used)\n" +
      "  {\n" +
      "    memcpy(tofu, cmock_call_instance->ReturnThruPtr_tofu_Val,\n" +
      "      cmock_call_instance->ReturnThruPtr_tofu_Size);\n" +
      "  }\n" +

    returned = @cmock_generator_plugin_return_thru_ptr.mock_implementation(@complex_func).join("")
  end

end
