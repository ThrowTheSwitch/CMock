# =========================================================================
#   CMock - Automatic Mock Generation for C
#   ThrowTheSwitch.org
#   Copyright (c) 2007-26 Mike Karlesky, Mark VanderVoord, & Greg Williams
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

    func_name = function[:name]

    # C function signature: always explicit depth for every pointer arg
    args_string = function[:args].map do |m|
      m[:ptr?] ? "#{@utils.arg_declaration(m)}, int #{m[:name]}_Depth" : @utils.arg_declaration(m)
    end.join(', ')

    # Short macro params: paired ptrs (before OR after) omit _Depth (auto-filled from paired size arg)
    args_call_i = function[:args].map do |m|
      m[:ptr?] && !m[:array_size_name] ? "#{m[:name]}, #{m[:name]}_Depth" : m[:name].to_s
    end.join(', ')

    # Short macro call: paired ptrs pass paired size name as depth automatically
    args_call_o = function[:args].map do |m|
      if m[:ptr?] && m[:array_size_name]
        "#{m[:name]}, (#{m[:array_size_name]})"
      elsif m[:ptr?]
        "#{m[:name]}, (#{m[:name]}_Depth)"
      else
        m[:name].to_s
      end
    end.join(', ')

    # Extended macro params: every ptr gets an explicit _Depth
    args_call_ext_i = function[:args].map do |m|
      m[:ptr?] ? "#{m[:name]}, #{m[:name]}_Depth" : m[:name].to_s
    end.join(', ')

    # Extended macro call: every ptr passes (name_Depth)
    args_call_ext_o = function[:args].map do |m|
      m[:ptr?] ? "#{m[:name]}, (#{m[:name]}_Depth)" : m[:name].to_s
    end.join(', ')

    has_paired = function[:args].any? { |m| m[:array_size_name] }

    lines = ''
    if function[:return][:void?]
      if @error_stubs
        lines << "#define #{func_name}_ExpectWithArrayAndReturn(#{args_call_i}, cmock_retval) TEST_FAIL_MESSAGE(\"#{func_name} requires _ExpectWithArray (not AndReturn)\");\n"
        lines << "#define #{func_name}_ExpectWithArrayExtendedAndReturn(#{args_call_ext_i}, cmock_retval) TEST_FAIL_MESSAGE(\"#{func_name} requires _ExpectWithArrayExtended (not AndReturn)\");\n" if has_paired
      end
      lines << "#define #{func_name}_ExpectWithArray(#{args_call_i}) #{func_name}_CMockExpectWithArray(__LINE__, #{args_call_o})\n"
      lines << "#define #{func_name}_ExpectWithArrayExtended(#{args_call_ext_i}) #{func_name}_CMockExpectWithArray(__LINE__, #{args_call_ext_o})\n" if has_paired
      lines << "void #{func_name}_CMockExpectWithArray(UNITY_LINE_TYPE cmock_line, #{args_string});\n"
    else
      if @error_stubs
        lines << "#define #{func_name}_ExpectWithArray(#{args_call_i}) TEST_FAIL_MESSAGE(\"#{func_name} requires _ExpectWithArrayAndReturn\");\n"
        lines << "#define #{func_name}_ExpectWithArrayExtended(#{args_call_ext_i}) TEST_FAIL_MESSAGE(\"#{func_name} requires _ExpectWithArrayExtendedAndReturn\");\n" if has_paired
      end
      lines << "#define #{func_name}_ExpectWithArrayAndReturn(#{args_call_i}, cmock_retval) #{func_name}_CMockExpectWithArrayAndReturn(__LINE__, #{args_call_o}, cmock_retval)\n"
      lines << "#define #{func_name}_ExpectWithArrayExtendedAndReturn(#{args_call_ext_i}, cmock_retval) #{func_name}_CMockExpectWithArrayAndReturn(__LINE__, #{args_call_ext_o}, cmock_retval)\n" if has_paired
      lines << "void #{func_name}_CMockExpectWithArrayAndReturn(UNITY_LINE_TYPE cmock_line, #{args_string}, #{function[:return][:str]});\n"
    end
    lines
  end

  def mock_interfaces(function)
    return nil unless function[:contains_ptr?]

    lines = []
    func_name = function[:name]

    # C function: always explicit depth for every pointer arg
    args_string = function[:args].map do |m|
      m[:ptr?] ? "#{@utils.arg_declaration(m)}, int #{m[:name]}_Depth" : @utils.arg_declaration(m)
    end.join(', ')

    # Call to CMockExpectParameters_: :before-paired ptrs pass only ptr name (their depth is set from paired size arg)
    call_string = function[:args].map do |m|
      m[:ptr?] && m[:array_size_order] != :before ? "#{m[:name]}, #{m[:name]}_Depth" : m[:name]
    end.join(', ')

    lines << if function[:return][:void?]
               "void #{func_name}_CMockExpectWithArray(UNITY_LINE_TYPE cmock_line, #{args_string})\n"
             else
               "void #{func_name}_CMockExpectWithArrayAndReturn(UNITY_LINE_TYPE cmock_line, #{args_string}, #{function[:return][:str]})\n"
             end
    lines << "{\n"
    lines << @utils.code_add_base_expectation(func_name)
    lines << "  CMockExpectParameters_#{func_name}(cmock_call_instance, #{call_string});\n"
    # Override depths for :before-paired pointers. CMockExpectParameters_ sets these from the paired
    # size arg; the explicit _Depth param here allows _ExpectWithArrayExtended to override that value.
    function[:args].each do |arg|
      lines << "  cmock_call_instance->Expected_#{arg[:name]}_Depth = #{arg[:name]}_Depth;\n" if arg[:ptr?] && arg[:array_size_order] == :before
    end
    lines << "  cmock_call_instance->ReturnVal = cmock_to_return;\n" unless function[:return][:void?]
    lines << "}\n\n"
  end
end
