# =========================================================================
#   CMock - Automatic Mock Generation for C
#   ThrowTheSwitch.org
#   Copyright (c) 2007-25 Mike Karlesky, Mark VanderVoord, & Greg Williams
#   SPDX-License-Identifier: MIT
# =========================================================================

require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require File.expand_path(File.dirname(__FILE__)) + '/../../lib/cmock_generator_plugin_array'
require File.expand_path(File.dirname(__FILE__)) + '/../../lib/cmock_generator_utils'

class UtilsStub
  def helpers
    {}
  end
  def arg_type_with_const(arg)
    CMockGeneratorUtils.arg_type_with_const(arg)
  end
  def code_add_base_expectation(func)
    "mock_retval_0"
  end
end

describe CMockGeneratorPluginArray, "Verify Generation Of Mock Function Declarations Without Error Stubs By CMockPGeneratorluginArray Module" do
  before do
    #no strict ordering
    @config = create_stub(
      :when_ptr => :compare_data,
      :enforce_strict_ordering => false,
      :respond_to? => true,
      :create_error_stubs => false)

    @utils = UtilsStub.new

    @cmock_generator_plugin_array = CMockGeneratorPluginArray.new(@config, @utils)
  end

  after do
  end

  it "add another mock function declaration for functions of style 'void func(int* tofu)'" do
    function = {:name => "Pine",
                :args => [{ :type => "int*",
                           :name => "tofu",
                           :ptr? => true,
                         }],
                :return => test_return[:void],
                :contains_ptr? => true }

    expected = "#define #{function[:name]}_ExpectWithArray(tofu, tofu_Depth) #{function[:name]}_CMockExpectWithArray(__LINE__, tofu, (tofu_Depth))\n" +
               "void #{function[:name]}_CMockExpectWithArray(UNITY_LINE_TYPE cmock_line, int* tofu, int tofu_Depth);\n"
    returned = @cmock_generator_plugin_array.mock_function_declarations(function)
    assert_equal(expected, returned)
  end

  it "add another mock function declaration for functions of style 'const char* func(int* tofu)'" do
    function = {:name => "Pine",
                :args => [{ :type => "int*",
                           :name => "tofu",
                           :ptr? => true,
                         }],
                :return => test_return[:string],
                :contains_ptr? => true }

    expected = "#define #{function[:name]}_ExpectWithArrayAndReturn(tofu, tofu_Depth, cmock_retval) #{function[:name]}_CMockExpectWithArrayAndReturn(__LINE__, tofu, (tofu_Depth), cmock_retval)\n" +
               "void #{function[:name]}_CMockExpectWithArrayAndReturn(UNITY_LINE_TYPE cmock_line, int* tofu, int tofu_Depth, const char* cmock_to_return);\n"
    returned = @cmock_generator_plugin_array.mock_function_declarations(function)
    assert_equal(expected, returned)
  end

  it "add another mock function declaration for functions of style 'const char* func(const int* tofu)'" do
    function = {:name => "Pine",
                :args => [{ :type   => "const int*",
                            :name   => "tofu",
                            :ptr?   => true,
                            :const? => true,
                         }],
                :return => test_return[:string],
                :contains_ptr? => true }

    expected = "#define #{function[:name]}_ExpectWithArrayAndReturn(tofu, tofu_Depth, cmock_retval) #{function[:name]}_CMockExpectWithArrayAndReturn(__LINE__, tofu, (tofu_Depth), cmock_retval)\n" +
               "void #{function[:name]}_CMockExpectWithArrayAndReturn(UNITY_LINE_TYPE cmock_line, const int* tofu, int tofu_Depth, const char* cmock_to_return);\n"
    returned = @cmock_generator_plugin_array.mock_function_declarations(function)
    assert_equal(expected, returned)
  end

end
