# =========================================================================
#   CMock - Automatic Mock Generation for C
#   ThrowTheSwitch.org
#   Copyright (c) 2007-25 Mike Karlesky, Mark VanderVoord, & Greg Williams
#   SPDX-License-Identifier: MIT
# =========================================================================

class CMockGeneratorPluginArray
  attr_reader :priority
  attr_accessor :config, :utils, :unity_helper, :ordered

  def initialize(config, utils)
    @config       = config
    @ptr_handling = @config.when_ptr
    @ordered      = @config.enforce_strict_ordering
    @error_stubs  = @config.create_error_stubs
    @utils        = utils
    @unity_helper = @utils.helpers[:unity_helper]
    @priority     = 8
  end

  def instance_typedefs(function)
    function[:args].inject('') do |all, arg|
      arg[:ptr?] ? all + "  int Expected_#{arg[:name]}_Depth;\n" : all
    end
  end

  def mock_function_declarations(function)
    return nil unless function[:contains_ptr?]

    args_call_i = function[:args].map { |m| m[:ptr?] ? "#{m[:name]}, #{m[:name]}_Depth" : (m[:name]).to_s }.join(', ')
    args_call_o = function[:args].map { |m| m[:ptr?] ? "#{m[:name]}, (#{m[:name]}_Depth)" : (m[:name]).to_s }.join(', ')
    args_string = function[:args].map do |m|
      type = @utils.arg_type_with_const(m)
      m[:ptr?] ? "#{type} #{m[:name]}, int #{m[:name]}_Depth" : "#{type} #{m[:name]}"
    end.join(', ')
    lines = ''
    if function[:return][:void?]
      lines << "#define #{function[:name]}_ExpectWithArrayAndReturn(#{args_call_i}, cmock_retval) TEST_FAIL_MESSAGE(\"#{function[:name]} requires _ExpectWithArray (not AndReturn)\");\n" if @error_stubs
      lines << "#define #{function[:name]}_ExpectWithArray(#{args_call_i}) #{function[:name]}_CMockExpectWithArray(__LINE__, #{args_call_o})\n"
      lines << "void #{function[:name]}_CMockExpectWithArray(UNITY_LINE_TYPE cmock_line, #{args_string});\n"
    else
      lines << "#define #{function[:name]}_ExpectWithArray(#{args_call_i}) TEST_FAIL_MESSAGE(\"#{function[:name]} requires _ExpectWithArrayAndReturn\");\n" if @error_stubs
      lines << "#define #{function[:name]}_ExpectWithArrayAndReturn(#{args_call_i}, cmock_retval) #{function[:name]}_CMockExpectWithArrayAndReturn(__LINE__, #{args_call_o}, cmock_retval)\n"
      lines << "void #{function[:name]}_CMockExpectWithArrayAndReturn(UNITY_LINE_TYPE cmock_line, #{args_string}, #{function[:return][:str]});\n"
    end
    lines
  end

  def mock_interfaces(function)
    return nil unless function[:contains_ptr?]

    lines = []
    func_name = function[:name]
    args_string = function[:args].map do |m|
      type = @utils.arg_type_with_const(m)
      m[:ptr?] ? "#{type} #{m[:name]}, int #{m[:name]}_Depth" : "#{type} #{m[:name]}"
    end.join(', ')
    call_string = function[:args].map { |m| m[:ptr?] ? "#{m[:name]}, #{m[:name]}_Depth" : m[:name] }.join(', ')
    lines << if function[:return][:void?]
               "void #{func_name}_CMockExpectWithArray(UNITY_LINE_TYPE cmock_line, #{args_string})\n"
             else
               "void #{func_name}_CMockExpectWithArrayAndReturn(UNITY_LINE_TYPE cmock_line, #{args_string}, #{function[:return][:str]})\n"
             end
    lines << "{\n"
    lines << @utils.code_add_base_expectation(func_name)
    lines << "  CMockExpectParameters_#{func_name}(cmock_call_instance, #{call_string});\n"
    lines << "  cmock_call_instance->ReturnVal = cmock_to_return;\n" unless function[:return][:void?]
    lines << "}\n\n"
  end
end
