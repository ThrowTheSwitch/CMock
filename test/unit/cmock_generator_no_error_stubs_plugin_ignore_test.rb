# =========================================================================
#   CMock - Automatic Mock Generation for C
#   ThrowTheSwitch.org
#   Copyright (c) 2007-25 Mike Karlesky, Mark VanderVoord, & Greg Williams
#   SPDX-License-Identifier: MIT
# =========================================================================

require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require File.expand_path(File.dirname(__FILE__)) + '/../../lib/cmock_generator_plugin_ignore'

describe CMockGeneratorPluginIgnore, "Verify Generation Of Mock Function Declarations Without Error Stubs By CMockGeneratorPluginIgnore Module" do

  before do
    create_mocks :config, :utils
    @config = create_stub(:respond_to? => true, :create_error_stubs => false)
    @cmock_generator_plugin_ignore = CMockGeneratorPluginIgnore.new(@config, @utils)
  end

  after do
  end

  it "handle function declarations for functions without return values" do
    function = {:name => "Mold", :args_string => "void", :return => test_return[:void]}
    expected = "#define Mold_Ignore() Mold_CMockIgnore()\n" +
               "void Mold_CMockIgnore(void);\n" +
               "#define Mold_StopIgnore() Mold_CMockStopIgnore()\n" +
               "void Mold_CMockStopIgnore(void);\n"
    returned = @cmock_generator_plugin_ignore.mock_function_declarations(function)
    assert_equal(expected, returned)
  end

  it "handle function declarations for functions that returns something" do
    function = {:name => "Fungus", :args_string => "void", :return => test_return[:string]}
    expected = "#define Fungus_IgnoreAndReturn(cmock_retval) Fungus_CMockIgnoreAndReturn(__LINE__, cmock_retval)\n"+
               "void Fungus_CMockIgnoreAndReturn(UNITY_LINE_TYPE cmock_line, const char* cmock_to_return);\n" +
               "#define Fungus_StopIgnore() Fungus_CMockStopIgnore()\n"+
               "void Fungus_CMockStopIgnore(void);\n"
    returned = @cmock_generator_plugin_ignore.mock_function_declarations(function)
    assert_equal(expected, returned)
  end

end
