# =========================================================================
#   CMock - Automatic Mock Generation for C
#   ThrowTheSwitch.org
#   Copyright (c) 2007-26 Mike Karlesky, Mark VanderVoord, & Greg Williams
#   SPDX-License-Identifier: MIT
# =========================================================================

require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require File.expand_path(File.dirname(__FILE__)) + '/../../lib/cmock_generator_plugin_expect'

describe CMockGeneratorPluginExpect, "Verify CMockGeneratorPluginExpect Module Without Global Ordering" do

  before do
    create_mocks :config, :utils

    @config = create_stub(
      :when_ptr => :compare_data,
      :enforce_strict_ordering => false,
      :respond_to? => true,
      :create_error_stubs => true,
      :plugins => [ :expect ],
      :debug_output => false )

    @utils.expect :helpers, {}
    @cmock_generator_plugin_expect = CMockGeneratorPluginExpect.new(@config, @utils)
  end

  after do
  end

  it "have set up internal priority on init" do
    assert_nil(@cmock_generator_plugin_expect.unity_helper)
    assert_equal(5, @cmock_generator_plugin_expect.priority)
  end

  it "not include any additional include files" do
    assert(!@cmock_generator_plugin_expect.respond_to?(:include_files))
  end

  it "add to typedef structure mock needs of functions of style 'void func(void)'" do
    function = {:name => "Oak", :args => [], :return => test_return[:void]}
    expected = ""
    returned = @cmock_generator_plugin_expect.instance_typedefs(function)
    assert_equal(expected, returned)
  end

  it "add to typedef structure mock needs of functions of style 'int func(void)'" do
    function = {:name => "Elm", :args => [], :return => test_return[:int]}
    expected = "  int ReturnVal;\n"
    returned = @cmock_generator_plugin_expect.instance_typedefs(function)
    assert_equal(expected, returned)
  end

  it "add to typedef structure mock needs of functions of style 'void func(int chicken, char* pork)'" do
    function = {:name => "Cedar", :args => [{ :name => "chicken", :type => "int"}, { :name => "pork", :type => "char*"}], :return => test_return[:void]}
    expected = "  int Expected_chicken;\n  char* Expected_pork;\n"
    returned = @cmock_generator_plugin_expect.instance_typedefs(function)
    assert_equal(expected, returned)
  end

  it "add to typedef structure mock needs of functions of style 'int func(float beef)'" do
    function = {:name => "Birch", :args => [{ :name => "beef", :type => "float"}], :return => test_return[:int]}
    expected = "  int ReturnVal;\n  float Expected_beef;\n"
    returned = @cmock_generator_plugin_expect.instance_typedefs(function)
    assert_equal(expected, returned)
  end

  it "add mock function declaration for functions of style 'void func(void)'" do
    function = {:name => "Maple", :args => [], :return => test_return[:void]}
    expected = "#define Maple_ExpectAndReturn(cmock_retval) TEST_FAIL_MESSAGE(\"Maple requires _Expect (not AndReturn)\");\n" +
               "#define Maple_Expect() Maple_CMockExpect(__LINE__)\n" +
               "void Maple_CMockExpect(UNITY_LINE_TYPE cmock_line);\n"
    returned = @cmock_generator_plugin_expect.mock_function_declarations(function)
    assert_equal(expected, returned)
  end

  it "add mock function declaration for functions of style 'int func(void)'" do
    function = {:name => "Spruce", :args => [], :return => test_return[:int]}
    expected = "#define Spruce_Expect() TEST_FAIL_MESSAGE(\"Spruce requires _ExpectAndReturn\");\n" +
               "#define Spruce_ExpectAndReturn(cmock_retval) Spruce_CMockExpectAndReturn(__LINE__, cmock_retval)\n" +
               "void Spruce_CMockExpectAndReturn(UNITY_LINE_TYPE cmock_line, int cmock_to_return);\n"
    returned = @cmock_generator_plugin_expect.mock_function_declarations(function)
    assert_equal(expected, returned)
  end

  it "add mock function declaration for functions of style 'const char* func(int tofu)'" do
    function = {:name => "Pine", :args => ["int tofu"], :args_string => "int tofu", :args_call => 'tofu', :return => test_return[:string]}
    expected = "#define Pine_Expect(tofu) TEST_FAIL_MESSAGE(\"Pine requires _ExpectAndReturn\");\n" +
               "#define Pine_ExpectAndReturn(tofu, cmock_retval) Pine_CMockExpectAndReturn(__LINE__, tofu, cmock_retval)\n" +
               "void Pine_CMockExpectAndReturn(UNITY_LINE_TYPE cmock_line, int tofu, const char* cmock_to_return);\n"
    returned = @cmock_generator_plugin_expect.mock_function_declarations(function)
    assert_equal(expected, returned)
  end

  it "add mock function implementation for functions of style 'void func(void)'" do
    function = {:name => "Apple", :args => [], :return => test_return[:void]}
    expected = ""
    returned = @cmock_generator_plugin_expect.mock_implementation(function)
    assert_equal(expected, returned)
  end

  it "add mock function implementation for functions of style 'int func(int veal, unsigned int sushi)'" do
    function = {:name => "Cherry", :args => [ { :type => "int", :name => "veal" }, { :type => "unsigned int", :name => "sushi" } ], :return => test_return[:int]}

    @utils.expect :code_verify_an_arg_expectation, " mocked_retval_1", [function, function[:args][0]]
    @utils.expect :code_verify_an_arg_expectation, " mocked_retval_2", [function, function[:args][1]]
    expected = " mocked_retval_1 mocked_retval_2"
    returned = @cmock_generator_plugin_expect.mock_implementation(function)
    assert_equal(expected, returned)
  end

  it "add mock function implementation using ordering if needed" do
    function = {:name => "Apple", :args => [], :return => test_return[:void]}
    expected = ""
    @cmock_generator_plugin_expect.ordered = true
    returned = @cmock_generator_plugin_expect.mock_implementation(function)
    assert_equal(expected, returned)
  end

  it "add mock interfaces for functions of style 'void func(void)'" do
    function = {:name => "Pear", :args => [], :args_string => "void", :return => test_return[:void]}
    @utils.expect :code_add_base_expectation, "mock_retval_0 ", ["Pear"]
    @utils.expect :code_call_argument_loader, "mock_retval_1 ", [function]
    expected = ["void Pear_CMockExpect(UNITY_LINE_TYPE cmock_line)\n",
                "{\n",
                "mock_retval_0 ",
                "mock_retval_1 ",
                "}\n\n"
               ].join
    returned = @cmock_generator_plugin_expect.mock_interfaces(function)
    assert_equal(expected, returned)
  end

  it "add mock interfaces for functions of style 'int func(void)'" do
    function = {:name => "Orange", :args => [], :args_string => "void", :return => test_return[:int]}
    @utils.expect :code_add_base_expectation, "mock_retval_0 ", ["Orange"]
    @utils.expect :code_call_argument_loader, "mock_retval_1 ", [function]
    @utils.expect :code_assign_argument_quickly, "mock_retval_2", ["cmock_call_instance->ReturnVal", function[:return]]
    expected = ["void Orange_CMockExpectAndReturn(UNITY_LINE_TYPE cmock_line, int cmock_to_return)\n",
                "{\n",
                "mock_retval_0 ",
                "mock_retval_1 ",
                "mock_retval_2",
                "}\n\n"
               ].join
    returned = @cmock_generator_plugin_expect.mock_interfaces(function)
    assert_equal(expected, returned)
  end

  it "add mock interfaces for functions of style 'int func(char* pescado)'" do
    function = {:name => "Lemon", :args => [{ :type => "char*", :name => "pescado"}], :args_string => "char* pescado", :return => test_return[:int]}
    @utils.expect :code_add_base_expectation, "mock_retval_0 ", ["Lemon"]
    @utils.expect :code_call_argument_loader, "mock_retval_1 ", [function]
    @utils.expect :code_assign_argument_quickly, "mock_retval_2", ["cmock_call_instance->ReturnVal", function[:return]]
    expected = ["void Lemon_CMockExpectAndReturn(UNITY_LINE_TYPE cmock_line, char* pescado, int cmock_to_return)\n",
                "{\n",
                "mock_retval_0 ",
                "mock_retval_1 ",
                "mock_retval_2",
                "}\n\n"
               ].join
    returned = @cmock_generator_plugin_expect.mock_interfaces(function)
    assert_equal(expected, returned)
  end

  it "add mock interfaces for functions when using ordering" do
    function = {:name => "Pear", :args => [], :args_string => "void", :return => test_return[:void]}
    @utils.expect :code_add_base_expectation, "mock_retval_0 ", ["Pear"]
    @utils.expect :code_call_argument_loader, "mock_retval_1 ", [function]
    expected = ["void Pear_CMockExpect(UNITY_LINE_TYPE cmock_line)\n",
                "{\n",
                "mock_retval_0 ",
                "mock_retval_1 ",
                "}\n\n"
               ].join
    @cmock_generator_plugin_expect.ordered = true
    returned = @cmock_generator_plugin_expect.mock_interfaces(function)
    assert_equal(expected, returned)
  end

  it "add mock verify lines" do
    function = {:name => "Banana" }
    expected = "  if (CMOCK_GUTS_NONE != call_instance)\n" \
               "  {\n" \
               "    UNITY_SET_DETAIL(CMockString_Banana);\n" \
               "    UNITY_TEST_FAIL(cmock_line, CMockStringCalledLess);\n" \
               "  }\n"
    returned = @cmock_generator_plugin_expect.mock_verify(function)
    assert_equal(expected, returned)
  end

  it "preserve const-pointer ordering in typedef struct fields for arguments" do
    function = {
      :name => "Willow",
      :args => [
        { :name => "ptr_to_const", :type => "const int*", :ptr? => true, :const? => true,  :const_ptr? => false },
        { :name => "const_ptr",    :type => "int*",        :ptr? => true, :const? => false, :const_ptr? => true  },
        { :name => "both_const",   :type => "const int*",  :ptr? => true, :const? => true,  :const_ptr? => true  },
        { :name => "plain_ptr",    :type => "int*",        :ptr? => true, :const? => false, :const_ptr? => false },
      ],
      :return => test_return[:void]
    }
    # Struct fields use arg[:type] directly (no reconstruction via arg_type_with_const):
    # - "const int*" preserved as "const int*" (pointer to const data)
    # - "int*" (from int* const) stored as "int*" — the const_ptr? is intentionally omitted
    #   because a const struct field can never be written to, making the mock unworkable
    # - "const int*" (from const int* const) similarly stored without the trailing const
    expected = "  const int* Expected_ptr_to_const;\n" +
               "  int* Expected_const_ptr;\n" +
               "  const int* Expected_both_const;\n" +
               "  int* Expected_plain_ptr;\n"
    returned = @cmock_generator_plugin_expect.instance_typedefs(function)
    assert_equal(expected, returned)
  end

  it "preserve const-before-pointer in return typedef struct field" do
    const_int_ptr_return = { :type => "const int*", :name => "cmock_to_return", :ptr? => true,
                             :const? => true, :const_ptr? => false, :void? => false,
                             :str => "const int* cmock_to_return" }
    function = { :name => "Elm", :args => [], :return => const_int_ptr_return }
    # ReturnVal uses return[:type] = "const int*"
    expected = "  const int* ReturnVal;\n"
    returned = @cmock_generator_plugin_expect.instance_typedefs(function)
    assert_equal(expected, returned)
  end

  it "preserve const on non-pointer custom type in mock function declaration but drop it from struct field" do
    function = {
      :name        => "myFunc",
      :args        => [{ :name => "t_MyType", :type => "MyType_t", :ptr? => false, :const? => true, :const_ptr? => false }],
      :args_string => "const MyType_t t_MyType",
      :args_call   => "t_MyType",
      :return      => test_return[:int]
    }
    # struct field uses arg[:type] directly — no const, so the field stays writable
    expected_typedef = "  int ReturnVal;\n" \
                       "  MyType_t Expected_t_MyType;\n"
    assert_equal(expected_typedef, @cmock_generator_plugin_expect.instance_typedefs(function))

    # function declaration uses args_string — const MyType_t must appear in the C signature
    expected_decl = "#define myFunc_Expect(t_MyType) TEST_FAIL_MESSAGE(\"myFunc requires _ExpectAndReturn\");\n" \
                    "#define myFunc_ExpectAndReturn(t_MyType, cmock_retval) myFunc_CMockExpectAndReturn(__LINE__, t_MyType, cmock_retval)\n" \
                    "void myFunc_CMockExpectAndReturn(UNITY_LINE_TYPE cmock_line, const MyType_t t_MyType, int cmock_to_return);\n"
    assert_equal(expected_decl, @cmock_generator_plugin_expect.mock_function_declarations(function))
  end

  it "store const-pointer return value without trailing const in typedef struct field (for writability)" do
    int_ptr_const_return = { :type => "int*", :name => "cmock_to_return", :ptr? => true,
                             :const? => false, :const_ptr? => true, :void? => false,
                             :str => "int* const cmock_to_return" }
    function = { :name => "Elm", :args => [], :return => int_ptr_const_return }
    # ReturnVal uses return[:type] = "int*"; the trailing const is intentionally dropped
    # so that the struct field remains assignable
    expected = "  int* ReturnVal;\n"
    returned = @cmock_generator_plugin_expect.instance_typedefs(function)
    assert_equal(expected, returned)
  end

  it "preserve const and pointer order in mock function declaration" do
    int_ptr_const_return = { :type => "int*", :name => "cmock_to_return", :ptr? => true,
                             :const? => false, :const_ptr? => true, :void? => false,
                             :str => "int* const cmock_to_return" }
    function = {
      :name        => "Cedar",
      :args        => [
        { :name => "p", :type => "const int*", :ptr? => true, :const? => true,  :const_ptr? => false },
        { :name => "q", :type => "int*",        :ptr? => true, :const? => false, :const_ptr? => true  }
      ],
      :args_string => "const int* p, int* const q",
      :args_call   => "p, q",
      :return      => int_ptr_const_return
    }
    expected = "#define Cedar_Expect(p, q) TEST_FAIL_MESSAGE(\"Cedar requires _ExpectAndReturn\");\n" +
               "#define Cedar_ExpectAndReturn(p, q, cmock_retval) Cedar_CMockExpectAndReturn(__LINE__, p, q, cmock_retval)\n" +
               "void Cedar_CMockExpectAndReturn(UNITY_LINE_TYPE cmock_line, const int* p, int* const q, int* const cmock_to_return);\n"
    returned = @cmock_generator_plugin_expect.mock_function_declarations(function)
    assert_equal(expected, returned)
  end

  it "preserve const-before-pointer return type in mock function declaration for void-arg functions" do
    const_int_ptr_return = { :type => "const int*", :name => "cmock_to_return", :ptr? => true,
                             :const? => true, :const_ptr? => false, :void? => false,
                             :str => "const int* cmock_to_return" }
    function = { :name => "Oak", :args => [], :args_string => "void", :args_call => "",
                 :return => const_int_ptr_return }
    expected = "#define Oak_Expect() TEST_FAIL_MESSAGE(\"Oak requires _ExpectAndReturn\");\n" +
               "#define Oak_ExpectAndReturn(cmock_retval) Oak_CMockExpectAndReturn(__LINE__, cmock_retval)\n" +
               "void Oak_CMockExpectAndReturn(UNITY_LINE_TYPE cmock_line, const int* cmock_to_return);\n"
    returned = @cmock_generator_plugin_expect.mock_function_declarations(function)
    assert_equal(expected, returned)
  end

  it "preserve const-after-pointer return type in mock function declaration for void-arg functions" do
    int_ptr_const_return = { :type => "int*", :name => "cmock_to_return", :ptr? => true,
                             :const? => false, :const_ptr? => true, :void? => false,
                             :str => "int* const cmock_to_return" }
    function = { :name => "Oak", :args => [], :args_string => "void", :args_call => "",
                 :return => int_ptr_const_return }
    expected = "#define Oak_Expect() TEST_FAIL_MESSAGE(\"Oak requires _ExpectAndReturn\");\n" +
               "#define Oak_ExpectAndReturn(cmock_retval) Oak_CMockExpectAndReturn(__LINE__, cmock_retval)\n" +
               "void Oak_CMockExpectAndReturn(UNITY_LINE_TYPE cmock_line, int* const cmock_to_return);\n"
    returned = @cmock_generator_plugin_expect.mock_function_declarations(function)
    assert_equal(expected, returned)
  end
end
