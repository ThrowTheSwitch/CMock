# ==========================================
#   CMock Project - Automatic Mock Generation for C
#   Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
#   [Released under MIT License. Please refer to license.txt for details]
# ========================================== 

require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require 'cmock_generator_plugin_ignore_arg'

class CMockGeneratorPluginIgnoreArgTest < Test::Unit::TestCase
  def setup
    create_mocks :config, :utils

    # int *Oak(void)"
    @void_func = {:name => "Oak", :args => [], :return => test_return[:int_ptr]}

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
    @cmock_generator_plugin_ignore_arg = CMockGeneratorPluginIgnoreArg.new(@config, @utils)
  end

  def teardown
  end

  should "have set up internal accessors correctly on init" do
    assert_equal(@utils,  @cmock_generator_plugin_ignore_arg.utils)
    assert_equal(10,      @cmock_generator_plugin_ignore_arg.priority)
  end
  
  should "not include any additional include files" do 
    assert(!@cmock_generator_plugin_ignore_arg.respond_to?(:include_files))
  end

  should "not add to typedef structure for functions with no args" do
    returned = @cmock_generator_plugin_ignore_arg.instance_typedefs(@void_func)
    assert_equal("", returned)
  end
  
  should "add to tyepdef structure mock needs of functions of style 'void func(int chicken, int* pork)'" do
    expected = "  int IgnoreArg_chicken;\n" +
               "  int IgnoreArg_beef;\n" +
               "  int IgnoreArg_tofu;\n"
    returned = @cmock_generator_plugin_ignore_arg.instance_typedefs(@complex_func)
    assert_equal(expected, returned)
  end

  should "add mock function declarations for all arguments" do
    expected =
      "#define Pine_IgnoreArg_chicken()" +
      " Pine_CMockIgnoreArg_chicken(__LINE__)\n" +
      "void Pine_CMockIgnoreArg_chicken(UNITY_LINE_TYPE cmock_line);\n" +

      "#define Pine_IgnoreArg_beef()" +
      " Pine_CMockIgnoreArg_beef(__LINE__)\n" +
      "void Pine_CMockIgnoreArg_beef(UNITY_LINE_TYPE cmock_line);\n" +

      "#define Pine_IgnoreArg_tofu()" +
      " Pine_CMockIgnoreArg_tofu(__LINE__)\n" +
      "void Pine_CMockIgnoreArg_tofu(UNITY_LINE_TYPE cmock_line);\n"

    returned = @cmock_generator_plugin_ignore_arg.mock_function_declarations(@complex_func)
    assert_equal(expected, returned)
  end

  should "add mock interfaces for all arguments" do
    expected =
      "void Pine_CMockIgnoreArg_chicken(UNITY_LINE_TYPE cmock_line)\n" +
      "{\n" +
      "  CMOCK_Pine_CALL_INSTANCE* cmock_call_instance = " +
        "cmock_call_instance = (CMOCK_Pine_CALL_INSTANCE*)CMock_Guts_GetAddressFor(CMock_Guts_MemEndOfChain(Mock.Pine_CallInstance));\n" +
      "  UNITY_TEST_ASSERT_NOT_NULL(cmock_call_instance, cmock_line, \"chicken IgnoreArg called before Expect on 'Pine'.\");\n" +
      "  cmock_call_instance->IgnoreArg_chicken = 1;\n" +
      "}\n\n" +

      "void Pine_CMockIgnoreArg_beef(UNITY_LINE_TYPE cmock_line)\n" +
      "{\n" +
      "  CMOCK_Pine_CALL_INSTANCE* cmock_call_instance = " +
        "cmock_call_instance = (CMOCK_Pine_CALL_INSTANCE*)CMock_Guts_GetAddressFor(CMock_Guts_MemEndOfChain(Mock.Pine_CallInstance));\n" +
      "  UNITY_TEST_ASSERT_NOT_NULL(cmock_call_instance, cmock_line, \"beef IgnoreArg called before Expect on 'Pine'.\");\n" +
      "  cmock_call_instance->IgnoreArg_beef = 1;\n" +
      "}\n\n" +

      "void Pine_CMockIgnoreArg_tofu(UNITY_LINE_TYPE cmock_line)\n" +
      "{\n" +
      "  CMOCK_Pine_CALL_INSTANCE* cmock_call_instance = " +
        "cmock_call_instance = (CMOCK_Pine_CALL_INSTANCE*)CMock_Guts_GetAddressFor(CMock_Guts_MemEndOfChain(Mock.Pine_CallInstance));\n" +
      "  UNITY_TEST_ASSERT_NOT_NULL(cmock_call_instance, cmock_line, \"tofu IgnoreArg called before Expect on 'Pine'.\");\n" +
      "  cmock_call_instance->IgnoreArg_tofu = 1;\n" +
      "}\n\n"

    returned = @cmock_generator_plugin_ignore_arg.mock_interfaces(@complex_func).join("")
    assert_equal(expected, returned)
  end

  should "not add a mock implementation" do
    assert(!@cmock_generator_plugin_ignore_arg.respond_to?(:mock_implementation))
  end

end
