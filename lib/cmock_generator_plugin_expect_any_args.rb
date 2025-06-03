# =========================================================================
#   CMock - Automatic Mock Generation for C
#   ThrowTheSwitch.org
#   Copyright (c) 2007-25 Mike Karlesky, Mark VanderVoord, & Greg Williams
#   SPDX-License-Identifier: MIT
# =========================================================================

class CMockGeneratorPluginExpectAnyArgs
  attr_reader :priority, :config, :utils

  def initialize(config, utils)
    @config = config
    @error_stubs = @config.create_error_stubs
    @utils = utils
    @priority = 3
  end

  def instance_typedefs(_function)
    "  char ExpectAnyArgsBool;\n"
  end

  def mock_function_declarations(function)
    lines = ''
    if function[:args].empty?
      lines << ''
    elsif function[:return][:void?]
      lines << "#define #{function[:name]}_ExpectAnyArgsAndReturn(cmock_retval) TEST_FAIL_MESSAGE(\"#{function[:name]} requires _ExpectAnyArgs (not AndReturn)\");\n" if @error_stubs
      lines << "#define #{function[:name]}_ExpectAnyArgs() #{function[:name]}_CMockExpectAnyArgs(__LINE__)\n"
      lines << "void #{function[:name]}_CMockExpectAnyArgs(UNITY_LINE_TYPE cmock_line);\n"
    else
      lines << "#define #{function[:name]}_ExpectAnyArgs() TEST_FAIL_MESSAGE(\"#{function[:name]} requires _ExpectAnyArgsAndReturn\");\n" if @error_stubs
      lines << "#define #{function[:name]}_ExpectAnyArgsAndReturn(cmock_retval) #{function[:name]}_CMockExpectAnyArgsAndReturn(__LINE__, cmock_retval)\n"
      lines << "void #{function[:name]}_CMockExpectAnyArgsAndReturn(UNITY_LINE_TYPE cmock_line, #{function[:return][:str]});\n"
    end
    lines
  end

  def mock_interfaces(function)
    lines = ''
    unless function[:args].empty?
      lines << if function[:return][:void?]
                 "void #{function[:name]}_CMockExpectAnyArgs(UNITY_LINE_TYPE cmock_line)\n{\n"
               else
                 "void #{function[:name]}_CMockExpectAnyArgsAndReturn(UNITY_LINE_TYPE cmock_line, #{function[:return][:str]})\n{\n"
               end
      lines << @utils.code_add_base_expectation(function[:name], true)
      unless function[:return][:void?]
        lines << "  cmock_call_instance->ReturnVal = cmock_to_return;\n"
      end
      lines << "  cmock_call_instance->ExpectAnyArgsBool = (char)1;\n"
      lines << "}\n\n"
    end
    lines
  end
end
