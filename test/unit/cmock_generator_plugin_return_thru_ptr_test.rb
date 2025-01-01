# =========================================================================
#   CMock - Automatic Mock Generation for C
#   ThrowTheSwitch.org
#   Copyright (c) 2007-25 Mike Karlesky, Mark VanderVoord, & Greg Williams
#   SPDX-License-Identifier: MIT
# =========================================================================

require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require File.expand_path(File.dirname(__FILE__)) + '/../../lib/cmock_generator_plugin_return_thru_ptr'

describe CMockGeneratorPluginReturnThruPtr, "Verify CMockGeneratorPluginReturnThruPtr Module" do

  before do
    create_mocks :config, :utils

    # int *Oak(void)"
    @void_func = {:name => "Oak", :args => [], :return => test_return[:int_ptr]}

    # char *Maple(int blah)
    @simple_func = {:name => "Maple",
                    :args => [{:name => "blah", :type => "int", :ptr? => false}],
                    :return  => test_return[:string],
                    :contains_ptr? => false}

    # void Pine(int chicken, const int beef, int *tofu, const char** buffer)
    @complex_func = {:name => "Pine",
                     :args => [{ :type => "int",
                                 :name => "chicken",
                                 :ptr? => false,
                               },
                               { :type   => "const int*",
                                 :name   => "beef",
                                 :ptr?   => true,
                                 :const? => true,
                               },
                               { :type => "int*",
                                 :name => "tofu",
                                 :ptr? => true,
                               },
                               { :type => "char**",
                                 :name => "bean_buffer",
                                 :ptr? => true,
                               }],
                     :return => test_return[:void],
                     :contains_ptr? => true }

    @void_ptr_func = {:name => "Spruce",
                      :args => [{ :type => "void*",
                                :name => "pork",
                                :ptr? => true,
                              },
                              { :type => "MY_FANCY_VOID*",
                                :name => "salad",
                                :ptr? => true,
                              }],
                      :return => test_return[:void],
                      :contains_ptr? => true }

    #no strict ordering
    @cmock_generator_plugin_return_thru_ptr = CMockGeneratorPluginReturnThruPtr.new(@config, @utils)
  end

  after do
  end

  def simple_func_expect
    @utils.expect :ptr_or_str?, false, ['int']
  end

  def complex_func_expect
    @utils.expect :ptr_or_str?, false, ['int']
    @utils.expect :ptr_or_str?, true, ['const int*']
    @utils.expect :ptr_or_str?, true, ['int*']
    @utils.expect :ptr_or_str?, true, ['char**']
  end

  def void_ptr_func_expect
    @utils.expect :ptr_or_str?, true, ['void*']
    @utils.expect :ptr_or_str?, true, ['MY_FANCY_VOID*']

    @config.expect :treat_as_void, ['MY_FANCY_VOID']
  end

  it "have set up internal priority correctly on init" do
    assert_equal(9, @cmock_generator_plugin_return_thru_ptr.priority)
  end

  it "not include any additional include files" do
    assert(!@cmock_generator_plugin_return_thru_ptr.respond_to?(:include_files))
  end

  it "not add to typedef structure for functions of style 'int* func(void)'" do
    returned = @cmock_generator_plugin_return_thru_ptr.instance_typedefs(@void_func)
    assert_equal("", returned)
  end

  it "add to tyepdef structure mock needs of functions of style 'void func(int chicken, const int beef, int* pork, char** bean_buffer)'" do
    complex_func_expect()
    expected = "  char ReturnThruPtr_tofu_Used;\n" +
               "  int const* ReturnThruPtr_tofu_Val;\n" +
               "  size_t ReturnThruPtr_tofu_Size;\n" +
               "  char ReturnThruPtr_bean_buffer_Used;\n" +
               "  char* const* ReturnThruPtr_bean_buffer_Val;\n" +
               "  size_t ReturnThruPtr_bean_buffer_Size;\n"
    returned = @cmock_generator_plugin_return_thru_ptr.instance_typedefs(@complex_func)
    assert_equal(expected, returned)
  end

  it "not add an additional mock interface for functions not containing pointers" do
    simple_func_expect()
    returned = @cmock_generator_plugin_return_thru_ptr.mock_function_declarations(@simple_func)
    assert_equal("", returned)
  end

  it "add a mock function declaration only for non-const pointer arguments" do
    complex_func_expect();

    expected =
      "#define Pine_ReturnThruPtr_tofu(tofu)" +
      " Pine_CMockReturnMemThruPtr_tofu(__LINE__, tofu, sizeof(int))\n" +
      "#define Pine_ReturnArrayThruPtr_tofu(tofu, cmock_len)" +
      " Pine_CMockReturnMemThruPtr_tofu(__LINE__, tofu, (cmock_len * sizeof(*tofu)))\n" +
      "#define Pine_ReturnMemThruPtr_tofu(tofu, cmock_size)" +
      " Pine_CMockReturnMemThruPtr_tofu(__LINE__, tofu, (cmock_size))\n" +
      "void Pine_CMockReturnMemThruPtr_tofu(UNITY_LINE_TYPE cmock_line, int const* tofu, size_t cmock_size);\n"+
      "#define Pine_ReturnThruPtr_bean_buffer(bean_buffer)" +
      " Pine_CMockReturnMemThruPtr_bean_buffer(__LINE__, bean_buffer, sizeof(char*))\n" +
      "#define Pine_ReturnArrayThruPtr_bean_buffer(bean_buffer, cmock_len)" +
      " Pine_CMockReturnMemThruPtr_bean_buffer(__LINE__, bean_buffer, (cmock_len * sizeof(*bean_buffer)))\n" +
      "#define Pine_ReturnMemThruPtr_bean_buffer(bean_buffer, cmock_size)" +
      " Pine_CMockReturnMemThruPtr_bean_buffer(__LINE__, bean_buffer, (cmock_size))\n" +
      "void Pine_CMockReturnMemThruPtr_bean_buffer(UNITY_LINE_TYPE cmock_line, char* const* bean_buffer, size_t cmock_size);\n"

    returned = @cmock_generator_plugin_return_thru_ptr.mock_function_declarations(@complex_func)
    assert_equal(expected, returned)
  end

  it "add a mock function declaration with sizeof(<name>) for void pointer arguments" do
    void_ptr_func_expect();

    expected =
    "#define Spruce_ReturnThruPtr_pork(pork)" +
    " Spruce_CMockReturnMemThruPtr_pork(__LINE__, pork, sizeof(*pork))\n" +
    "#define Spruce_ReturnArrayThruPtr_pork(pork, cmock_len)" +
    " Spruce_CMockReturnMemThruPtr_pork(__LINE__, pork, (cmock_len * sizeof(*pork)))\n" +
    "#define Spruce_ReturnMemThruPtr_pork(pork, cmock_size)" +
    " Spruce_CMockReturnMemThruPtr_pork(__LINE__, pork, (cmock_size))\n" +
    "void Spruce_CMockReturnMemThruPtr_pork(UNITY_LINE_TYPE cmock_line, void const* pork, size_t cmock_size);\n" + 
    "#define Spruce_ReturnThruPtr_salad(salad)" +
    " Spruce_CMockReturnMemThruPtr_salad(__LINE__, salad, sizeof(*salad))\n" +
    "#define Spruce_ReturnArrayThruPtr_salad(salad, cmock_len)" +
    " Spruce_CMockReturnMemThruPtr_salad(__LINE__, salad, (cmock_len * sizeof(*salad)))\n" +
    "#define Spruce_ReturnMemThruPtr_salad(salad, cmock_size)" +
    " Spruce_CMockReturnMemThruPtr_salad(__LINE__, salad, (cmock_size))\n" +
    "void Spruce_CMockReturnMemThruPtr_salad(UNITY_LINE_TYPE cmock_line, MY_FANCY_VOID const* salad, size_t cmock_size);\n"

    returned = @cmock_generator_plugin_return_thru_ptr.mock_function_declarations(@void_ptr_func)
    assert_equal(expected, returned)
  end

  it "add mock interfaces only for non-const pointer arguments" do
    complex_func_expect();

    expected =
      "void Pine_CMockReturnMemThruPtr_tofu(UNITY_LINE_TYPE cmock_line, int const* tofu, size_t cmock_size)\n" +
      "{\n" +
      "  CMOCK_Pine_CALL_INSTANCE* cmock_call_instance = " +
      "(CMOCK_Pine_CALL_INSTANCE*)CMock_Guts_GetAddressFor(CMock_Guts_MemEndOfChain(Mock.Pine_CallInstance));\n" +
      "  UNITY_TEST_ASSERT_NOT_NULL(cmock_call_instance, cmock_line, CMockStringPtrPreExp);\n" +
      "  cmock_call_instance->ReturnThruPtr_tofu_Used = 1;\n" +
      "  cmock_call_instance->ReturnThruPtr_tofu_Val = tofu;\n" +
      "  cmock_call_instance->ReturnThruPtr_tofu_Size = cmock_size;\n" +
      "}\n\n" +
      "void Pine_CMockReturnMemThruPtr_bean_buffer(UNITY_LINE_TYPE cmock_line, char* const* bean_buffer, size_t cmock_size)\n" +
      "{\n" +
      "  CMOCK_Pine_CALL_INSTANCE* cmock_call_instance = " +
      "(CMOCK_Pine_CALL_INSTANCE*)CMock_Guts_GetAddressFor(CMock_Guts_MemEndOfChain(Mock.Pine_CallInstance));\n" +
      "  UNITY_TEST_ASSERT_NOT_NULL(cmock_call_instance, cmock_line, CMockStringPtrPreExp);\n" +
      "  cmock_call_instance->ReturnThruPtr_bean_buffer_Used = 1;\n" +
      "  cmock_call_instance->ReturnThruPtr_bean_buffer_Val = bean_buffer;\n" +
      "  cmock_call_instance->ReturnThruPtr_bean_buffer_Size = cmock_size;\n" +
      "}\n\n"

    returned = @cmock_generator_plugin_return_thru_ptr.mock_interfaces(@complex_func).join("")
    assert_equal(expected, returned)
  end

  it "add mock implementations only for non-const pointer arguments" do
    complex_func_expect()

    expected =
      "  if (cmock_call_instance->ReturnThruPtr_tofu_Used)\n" +
      "  {\n" +
      "    UNITY_TEST_ASSERT_NOT_NULL(tofu, cmock_line, CMockStringPtrIsNULL);\n" +
      "    memcpy((void*)tofu, (const void*)cmock_call_instance->ReturnThruPtr_tofu_Val,\n" +
      "      cmock_call_instance->ReturnThruPtr_tofu_Size);\n" +
      "  }\n" +
      "  if (cmock_call_instance->ReturnThruPtr_bean_buffer_Used)\n" +
      "  {\n" +
      "    UNITY_TEST_ASSERT_NOT_NULL(bean_buffer, cmock_line, CMockStringPtrIsNULL);\n" +
      "    memcpy((void*)bean_buffer, (const void*)cmock_call_instance->ReturnThruPtr_bean_buffer_Val,\n" +
      "      cmock_call_instance->ReturnThruPtr_bean_buffer_Size);\n" +
      "  }\n"

    returned = @cmock_generator_plugin_return_thru_ptr.mock_implementation(@complex_func).join("")
    assert_equal(expected, returned)
  end

end
