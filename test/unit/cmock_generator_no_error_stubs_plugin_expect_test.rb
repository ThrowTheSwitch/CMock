# =========================================================================
#   CMock - Automatic Mock Generation for C
#   ThrowTheSwitch.org
#   Copyright (c) 2007-25 Mike Karlesky, Mark VanderVoord, & Greg Williams
#   SPDX-License-Identifier: MIT
# =========================================================================

require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require File.expand_path(File.dirname(__FILE__)) + '/../../lib/cmock_generator_plugin_expect'

describe CMockGeneratorPluginExpect, "Verify Generation Of Mock Function Declarations Without Error Stubs By CMockGeneratorPluginExpect Module" do

  before do
    create_mocks :config, :utils

    @config = create_stub(
      :when_ptr => :compare_data,
      :enforce_strict_ordering => false,
      :respond_to? => true,
      :create_error_stubs => false,
      :plugins => [ :expect ] )

    @utils.expect :helpers, {}
    @cmock_generator_plugin_expect = CMockGeneratorPluginExpect.new(@config, @utils)
  end

  after do
  end

  it "add mock function declarations for functions of style 'void func(void)'" do
    function = {:name => "Maple", :args => [], :return => test_return[:void]}
    expected = "#define Maple_Expect() Maple_CMockExpect(__LINE__)\n" +
               "void Maple_CMockExpect(UNITY_LINE_TYPE cmock_line);\n"
    returned = @cmock_generator_plugin_expect.mock_function_declarations(function)
    assert_equal(expected, returned)
  end

  it "add mock function declarations for functions of style 'int func(void)'" do
    function = {:name => "Spruce", :args => [], :return => test_return[:int]}
    expected = "#define Spruce_ExpectAndReturn(cmock_retval) Spruce_CMockExpectAndReturn(__LINE__, cmock_retval)\n" +
               "void Spruce_CMockExpectAndReturn(UNITY_LINE_TYPE cmock_line, int cmock_to_return);\n"
    returned = @cmock_generator_plugin_expect.mock_function_declarations(function)
    assert_equal(expected, returned)
  end

  it "add mock function declarations for functions of style 'const char* func(int tofu)'" do
    function = {:name => "Pine", :args => ["int tofu"], :args_string => "int tofu", :args_call => 'tofu', :return => test_return[:string]}
    expected = "#define Pine_ExpectAndReturn(tofu, cmock_retval) Pine_CMockExpectAndReturn(__LINE__, tofu, cmock_retval)\n" +
               "void Pine_CMockExpectAndReturn(UNITY_LINE_TYPE cmock_line, int tofu, const char* cmock_to_return);\n"
    returned = @cmock_generator_plugin_expect.mock_function_declarations(function)
    assert_equal(expected, returned)
  end

end
