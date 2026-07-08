# =========================================================================
#   CMock - Automatic Mock Generation for C
#   ThrowTheSwitch.org
#   Copyright (c) 2007-26 Mike Karlesky, Mark VanderVoord, & Greg Williams
#   SPDX-License-Identifier: MIT
# =========================================================================

class CMockGeneratorPluginExpect
  attr_reader :priority
  attr_accessor :config, :utils, :unity_helper, :ordered

  def initialize(config, utils)
    @config       = config
    @ptr_handling = @config.when_ptr
    @ordered      = @config.enforce_strict_ordering
    @error_stubs  = @config.create_error_stubs
    @utils        = utils
    @unity_helper = @utils.helpers[:unity_helper]
    @priority     = 5
    @debug_output = @config.debug_output

    if @config.plugins.include? :expect_any_args
      alias :mock_implementation :mock_implementation_might_check_args
    else
      alias :mock_implementation :mock_implementation_always_check_args
    end
  end

  def instance_typedefs(function)
    lines = ''
    lines << "  #{function[:return][:type]} ReturnVal;\n"  unless function[:return][:void?]
    lines << "  int CallOrder;\n"                          if @ordered
    function[:args].each do |arg|
      lines << "  #{arg[:type]} Expected_#{arg[:name]};\n"
    end
    lines
  end

  def mock_function_declarations(function)
    lines = ''
    if function[:args].empty?
      if function[:return][:void?]
        lines << "#define #{function[:name]}_ExpectAndReturn(cmock_retval) TEST_FAIL_MESSAGE(\"#{function[:name]} requires _Expect (not AndReturn)\");\n" if @error_stubs
        lines << "#define #{function[:name]}_Expect() #{function[:name]}_CMockExpect(__LINE__)\n"
        lines << "void #{function[:name]}_CMockExpect(UNITY_LINE_TYPE cmock_line);\n"
      else
        lines << "#define #{function[:name]}_Expect() TEST_FAIL_MESSAGE(\"#{function[:name]} requires _ExpectAndReturn\");\n" if @error_stubs
        lines << "#define #{function[:name]}_ExpectAndReturn(cmock_retval) #{function[:name]}_CMockExpectAndReturn(__LINE__, cmock_retval)\n"
        lines << "void #{function[:name]}_CMockExpectAndReturn(UNITY_LINE_TYPE cmock_line, #{function[:return][:str]});\n"
      end
    elsif function[:return][:void?]
      lines << "#define #{function[:name]}_ExpectAndReturn(#{function[:args_call]}, cmock_retval) TEST_FAIL_MESSAGE(\"#{function[:name]} requires _Expect (not AndReturn)\");\n" if @error_stubs
      lines << "#define #{function[:name]}_Expect(#{function[:args_call]}) #{function[:name]}_CMockExpect(__LINE__, #{function[:args_call]})\n"
      lines << "void #{function[:name]}_CMockExpect(UNITY_LINE_TYPE cmock_line, #{helper_args_string(function)});\n"
    else
      lines << "#define #{function[:name]}_Expect(#{function[:args_call]}) TEST_FAIL_MESSAGE(\"#{function[:name]} requires _ExpectAndReturn\");\n" if @error_stubs
      lines << "#define #{function[:name]}_ExpectAndReturn(#{function[:args_call]}, cmock_retval) #{function[:name]}_CMockExpectAndReturn(__LINE__, #{function[:args_call]}, cmock_retval)\n"
      lines << "void #{function[:name]}_CMockExpectAndReturn(UNITY_LINE_TYPE cmock_line, #{helper_args_string(function)}, #{function[:return][:str]});\n"
    end
    lines
  end

  def mock_implementation_always_check_args(function)
    lines = ''
    function[:args].each do |arg|
      lines << @utils.code_verify_an_arg_expectation(function, arg)
    end
    lines
  end

  def mock_implementation_might_check_args(function)
    return '' if function[:args].empty?

    lines = "  if (!cmock_call_instance->ExpectAnyArgsBool)\n  {\n"
    function[:args].each do |arg|
      lines << @utils.code_verify_an_arg_expectation(function, arg)
    end
    lines << "  }\n"
    lines
  end

  def mock_interfaces(function)
    lines = ''
    func_name = function[:name]
    lines << if function[:return][:void?]
               if function[:args_string] == 'void'
                 "void #{func_name}_CMockExpect(UNITY_LINE_TYPE cmock_line)\n{\n"
               else
                 "void #{func_name}_CMockExpect(UNITY_LINE_TYPE cmock_line, #{helper_args_string(function)})\n{\n"
               end
             elsif function[:args_string] == 'void'
               "void #{func_name}_CMockExpectAndReturn(UNITY_LINE_TYPE cmock_line, #{function[:return][:str]})\n{\n"
             else
               "void #{func_name}_CMockExpectAndReturn(UNITY_LINE_TYPE cmock_line, #{helper_args_string(function)}, #{function[:return][:str]})\n{\n"
             end
    lines << "  TEST_MESSAGE(\"CMock: #{func_name}_#{function[:return][:void?] ? 'Expect' : 'ExpectAndReturn'} called\");\n" if @debug_output
    lines << @utils.code_add_base_expectation(func_name)
    lines << @utils.code_call_argument_loader(function)
    lines << @utils.code_assign_argument_quickly('cmock_call_instance->ReturnVal', function[:return]) unless function[:return][:void?]
    lines << "}\n\n"
  end

  def mock_verify(function)
    "  if (CMOCK_GUTS_NONE != call_instance)\n" \
    "  {\n" \
    "    UNITY_SET_DETAIL(CMockString_#{function[:name]});\n" \
    "    UNITY_TEST_FAIL(cmock_line, CMockStringCalledLess);\n" \
    "  }\n"
  end

  private

  # Build args string for generated _CMockExpect/_CMockExpectAndReturn helper signatures.
  # Converts flat array parameters (e.g. POINT_T a[N]) to pointer notation (POINT_T* a)
  # to avoid GCC -Wstringop-overflow, which treats static array sizes in function
  # parameters as bounds hints and errors when callers pass smaller objects.
  def helper_args_string(function)
    return function[:args_string] if function[:args_string] == 'void'
    return function[:args_string] unless function[:args]&.any? { |m| m.is_a?(Hash) && m[:array_dims] }

    function[:args].map { |m| CMockGeneratorUtils.arg_declaration(m) }.join(', ')
  end
end
