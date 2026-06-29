# =========================================================================
#   CMock - Automatic Mock Generation for C
#   ThrowTheSwitch.org
#   Copyright (c) 2007-26 Mike Karlesky, Mark VanderVoord, & Greg Williams
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

    # void Cedar(volatile struct foo_obj *foo_handle)
    # arg[:type] has volatile stripped at parse time; volatile? flag carries the information
    @volatile_ptr_func = {:name => "Cedar",
                          :args => [{ :type      => "struct foo_obj*",
                                      :name      => "foo_handle",
                                      :ptr?      => true,
                                      :volatile? => true,
                                    }],
                          :return => test_return[:void],
                          :contains_ptr? => true }

    #no strict ordering
    @config.expect :plugins, []
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

  def volatile_ptr_func_expect
    @utils.expect :ptr_or_str?, true, ['struct foo_obj*']
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
      "    CMOCK_MEMCPY((void*)tofu, (const void*)cmock_call_instance->ReturnThruPtr_tofu_Val,\n" +
      "      cmock_call_instance->ReturnThruPtr_tofu_Size);\n" +
      "  }\n" +
      "  if (cmock_call_instance->ReturnThruPtr_bean_buffer_Used)\n" +
      "  {\n" +
      "    UNITY_TEST_ASSERT_NOT_NULL(bean_buffer, cmock_line, CMockStringPtrIsNULL);\n" +
      "    CMOCK_MEMCPY((void*)bean_buffer, (const void*)cmock_call_instance->ReturnThruPtr_bean_buffer_Val,\n" +
      "      cmock_call_instance->ReturnThruPtr_bean_buffer_Size);\n" +
      "  }\n"

    returned = @cmock_generator_plugin_return_thru_ptr.mock_implementation(@complex_func).join("")
    assert_equal(expected, returned)
  end

  it "has no volatile in the Val typedef member for a volatile pointer arg (type is pre-stripped)" do
    volatile_ptr_func_expect()

    # arg[:type] = "struct foo_obj*" (volatile stripped at parse time)
    # ptr_to_const("struct foo_obj*") => "struct foo_obj const*"
    expected = "  char ReturnThruPtr_foo_handle_Used;\n" +
               "  struct foo_obj const* ReturnThruPtr_foo_handle_Val;\n" +
               "  size_t ReturnThruPtr_foo_handle_Size;\n"

    returned = @cmock_generator_plugin_return_thru_ptr.instance_typedefs(@volatile_ptr_func)
    assert_equal(expected, returned)
  end

  it "has no volatile in the _CMockReturnMemThruPtr_ declaration for a volatile pointer arg" do
    volatile_ptr_func_expect()

    # arg[:type] = "struct foo_obj*" (volatile stripped), so sizeof and param type are clean.
    expected =
      "#define Cedar_ReturnThruPtr_foo_handle(foo_handle)" +
      " Cedar_CMockReturnMemThruPtr_foo_handle(__LINE__, foo_handle, sizeof(struct foo_obj))\n" +
      "#define Cedar_ReturnArrayThruPtr_foo_handle(foo_handle, cmock_len)" +
      " Cedar_CMockReturnMemThruPtr_foo_handle(__LINE__, foo_handle, (cmock_len * sizeof(*foo_handle)))\n" +
      "#define Cedar_ReturnMemThruPtr_foo_handle(foo_handle, cmock_size)" +
      " Cedar_CMockReturnMemThruPtr_foo_handle(__LINE__, foo_handle, (cmock_size))\n" +
      "void Cedar_CMockReturnMemThruPtr_foo_handle(UNITY_LINE_TYPE cmock_line, struct foo_obj const* foo_handle, size_t cmock_size);\n"

    returned = @cmock_generator_plugin_return_thru_ptr.mock_function_declarations(@volatile_ptr_func)
    assert_equal(expected, returned)
  end

  it "uses (void*)(CMOCK_MEM_PTR_AS_INT) cast in mock_implementation for volatile pointer arg" do
    volatile_ptr_func_expect()

    expected =
      "  if (cmock_call_instance->ReturnThruPtr_foo_handle_Used)\n" +
      "  {\n" +
      "    UNITY_TEST_ASSERT_NOT_NULL(foo_handle, cmock_line, CMockStringPtrIsNULL);\n" +
      "    CMOCK_MEMCPY((void*)(CMOCK_MEM_PTR_AS_INT)foo_handle, (const void*)cmock_call_instance->ReturnThruPtr_foo_handle_Val,\n" +
      "      cmock_call_instance->ReturnThruPtr_foo_handle_Size);\n" +
      "  }\n"

    returned = @cmock_generator_plugin_return_thru_ptr.mock_implementation(@volatile_ptr_func).join("")
    assert_equal(expected, returned)
  end

  it "converts single pointer type to pointer-to-const via ptr_to_const" do
    plugin = @cmock_generator_plugin_return_thru_ptr
    assert_equal("int const*",     plugin.ptr_to_const("int*"))
    assert_equal("char const*",    plugin.ptr_to_const("char*"))
    assert_equal("uint8_t const*", plugin.ptr_to_const("uint8_t*"))
    assert_equal("void const*",    plugin.ptr_to_const("void*"))
    assert_equal("MY_TYPE const*", plugin.ptr_to_const("MY_TYPE*"))
  end

  it "converts double pointer type by making inner pointer const via ptr_to_const" do
    plugin = @cmock_generator_plugin_return_thru_ptr
    assert_equal("char* const*",   plugin.ptr_to_const("char**"))
    assert_equal("int* const*",    plugin.ptr_to_const("int**"))
  end

  it "includes int* const args (const pointer, mutable data) in typedef but excludes const int* args" do
    # int* const: const_ptr?=true, const?=false → data is mutable, pointer is const
    # The condition `!(arg[:const?])` checks whether the POINTED-TO data is const.
    # const? is about the data, not the pointer itself, so int* const IS included.
    const_ptr_func = {
      :name => "Birch",
      :args => [
        { :type => "int*",       :name => "mutable_ptr",  :ptr? => true, :const? => false, :const_ptr? => false },
        { :type => "int*",       :name => "const_ptr",    :ptr? => true, :const? => false, :const_ptr? => true  },
        { :type => "const int*", :name => "ptr_to_const", :ptr? => true, :const? => true,  :const_ptr? => false },
      ],
      :return => test_return[:void]
    }

    @utils.expect :ptr_or_str?, true, ["int*"]
    @utils.expect :ptr_or_str?, true, ["int*"]
    @utils.expect :ptr_or_str?, true, ["const int*"]

    # mutable_ptr and const_ptr are included; ptr_to_const is excluded (const?=true)
    expected = "  char ReturnThruPtr_mutable_ptr_Used;\n" +
               "  int const* ReturnThruPtr_mutable_ptr_Val;\n" +
               "  size_t ReturnThruPtr_mutable_ptr_Size;\n" +
               "  char ReturnThruPtr_const_ptr_Used;\n" +
               "  int const* ReturnThruPtr_const_ptr_Val;\n" +
               "  size_t ReturnThruPtr_const_ptr_Size;\n"

    returned = @cmock_generator_plugin_return_thru_ptr.instance_typedefs(const_ptr_func)
    assert_equal(expected, returned)
  end

  it "generates correct function signature for int* const args in mock interface" do
    const_ptr_func = {
      :name => "Birch",
      :args => [
        { :type => "int*", :name => "const_ptr", :ptr? => true, :const? => false, :const_ptr? => true },
      ],
      :return => test_return[:void]
    }

    @utils.expect :ptr_or_str?, true, ["int*"]

    # ptr_to_const("int*") = "int const*", so the helper function takes int const* const_ptr
    expected =
      "#define Birch_ReturnThruPtr_const_ptr(const_ptr)" +
      " Birch_CMockReturnMemThruPtr_const_ptr(__LINE__, const_ptr, sizeof(int))\n" +
      "#define Birch_ReturnArrayThruPtr_const_ptr(const_ptr, cmock_len)" +
      " Birch_CMockReturnMemThruPtr_const_ptr(__LINE__, const_ptr, (cmock_len * sizeof(*const_ptr)))\n" +
      "#define Birch_ReturnMemThruPtr_const_ptr(const_ptr, cmock_size)" +
      " Birch_CMockReturnMemThruPtr_const_ptr(__LINE__, const_ptr, (cmock_size))\n" +
      "void Birch_CMockReturnMemThruPtr_const_ptr(UNITY_LINE_TYPE cmock_line, int const* const_ptr, size_t cmock_size);\n"

    returned = @cmock_generator_plugin_return_thru_ptr.mock_function_declarations(const_ptr_func)
    assert_equal(expected, returned)
  end

end
