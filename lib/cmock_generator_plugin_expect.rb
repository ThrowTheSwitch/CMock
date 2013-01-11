# ==========================================
#   CMock Project - Automatic Mock Generation for C
#   Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
#   [Released under MIT License. Please refer to license.txt for details]
# ========================================== 

class CMockGeneratorPluginExpect

  attr_reader :priority
  attr_accessor :config, :utils, :unity_helper, :ordered

  def initialize(config, utils)
    @config       = config
    @ptr_handling = @config.when_ptr
    @ordered      = @config.enforce_strict_ordering
    @utils        = utils
    @unity_helper = @utils.helpers[:unity_helper]
    @priority     = 5
    @api          = "MOCKGOTHIC_API"
  end

  def instance_typedefs(function)
    lines = ""
    lines << "  #{function[:return][:type]} ReturnVal;\n"  unless (function[:return][:void?])
    lines << "  int CallOrder;\n"                          if (@ordered)
    function[:args].each do |arg|
      lines << "  #{arg[:type]} Expected_#{arg[:name]};\n"
    end
    lines
  end

  def expect_arguments(function)
    lines = ""
    function[:args].each do |arg|
      lines << "  int ExpectResult_#{arg[:name]};\n"
    end
    lines
  end

  #
  #
  #
  #
  #
  def expect_result(function)
    return "#{@api} int #{function[:name]}_CMockExpectedResult();\n"
  end

  #
  #
  #
  #
  #
  def expect_declaration(function)
    lines = ""
    function[:args].each do |arg|
      lines << "      if (CMOCK_#{function[:name]}_EXPECT_RESULT.ExpectResult_#{arg[:name]} == 1)\n      {\n"
      lines << "        return 1; // Function called with incorrect value. \n      }\n"
    end
    lines
  end

  #
  #
  #
  #
  #
  def expect_result_reset(function)
    return "#{@api} void #{function[:name]}_CMockResetExpectedResult();\n"
  end

  #
  #
  #
  #
  #
  def expect_reset_arguments(function)
    lines = ""
    function[:args].each do |arg|
      lines << "  CMOCK_#{function[:name]}_EXPECT_RESULT.ExpectResult_#{arg[:name]} = 0;\n"
    end
    lines
  end

  #
  #
  #
  #
  #
  def mock_function_declarations(function)

    expect_function = expect_result(function)
    expect_reset_function = expect_result_reset(function)
    if (function[:args].empty?)
      if (function[:return][:void?])
        return "#define #{function[:name]}_Expect() #{function[:name]}_CMockExpect(__LINE__)\n" +
               "#{@api} void #{function[:name]}_CMockExpect(UNITY_LINE_TYPE cmock_line);\n" +
               "#{expect_function}" +
               "#{expect_reset_function}"
      else
        return "#define #{function[:name]}_ExpectAndReturn(cmock_retval) #{function[:name]}_CMockExpectAndReturn(__LINE__, cmock_retval)\n" +
               "#{@api} void #{function[:name]}_CMockExpectAndReturn(UNITY_LINE_TYPE cmock_line, #{function[:return][:str]});\n" +
               "#{expect_function}" +
               "#{expect_reset_function}"
      end
    else        
      if (function[:return][:void?])
        return "#define #{function[:name]}_Expect(#{function[:args_call]}) #{function[:name]}_CMockExpect(__LINE__, #{function[:args_call]})\n" +
               "#{@api} void #{function[:name]}_CMockExpect(UNITY_LINE_TYPE cmock_line, #{function[:args_string]});\n" +
               "#{expect_function}" +
               "#{expect_reset_function}"
      else
        return "#define #{function[:name]}_ExpectAndReturn(#{function[:args_call]}, cmock_retval) #{function[:name]}_CMockExpectAndReturn(__LINE__, #{function[:args_call]}, cmock_retval)\n" +
               "#{@api} void #{function[:name]}_CMockExpectAndReturn(UNITY_LINE_TYPE cmock_line, #{function[:args_string]}, #{function[:return][:str]});\n" +
               "#{expect_function}" +
               "#{expect_reset_function}"
      end
    end
  end

  #
  #
  #
  #
  #
  def mock_implementation(function)
    lines = ""
    lines << "  CMOCK_#{function[:name]}_EXPECT_RESULT.ExpectCalled = 1;\n"
    function[:args].each do |arg|
      lines << @utils.code_verify_an_arg_expectation(function, arg)
    end
    lines
  end

  #
  #
  #
  #
  #
  def mock_interfaces(function)
    lines = ""
    func_name = function[:name]
    if (function[:return][:void?])
      if (function[:args_string] == "void")
        lines << "#{@api} void #{func_name}_CMockExpect(UNITY_LINE_TYPE cmock_line)\n{\n"
      else
        lines << "#{@api} void #{func_name}_CMockExpect(UNITY_LINE_TYPE cmock_line, #{function[:args_string]})\n{\n"
      end
    else
      if (function[:args_string] == "void")
        lines << "#{@api} void #{func_name}_CMockExpectAndReturn(UNITY_LINE_TYPE cmock_line, #{function[:return][:str]})\n{\n"
      else
        lines << "#{@api} void #{func_name}_CMockExpectAndReturn(UNITY_LINE_TYPE cmock_line, #{function[:args_string]}, #{function[:return][:str]})\n{\n"
      end
    end
    lines << @utils.code_add_base_expectation(func_name)
    lines << @utils.code_call_argument_loader(function)
    lines << @utils.code_assign_argument_quickly("cmock_call_instance->ReturnVal", function[:return]) unless (function[:return][:void?])
    lines << "}\n\n"
  end

  #
  #
  #
  #
  #
  def mock_verify(function)
    func_name = function[:name]

    definition = preprocessor_formatting(function)
    file_name = filename_format(function)
    if (definition.include?(file_name))
      definition = ''
    end
    "  #{definition}\n  UNITY_TEST_ASSERT(CMOCK_GUTS_NONE == Mock.#{func_name}_CallInstance, cmock_line, \"Function '#{func_name}' called less times than expected.\");\n  if (#{func_name}_CMockExpectedResult() == 1)\n    {return 1;} // Function called with incorrect argument values.\n" 
  end

  #
  #
  #
  #
  #
  def mock_destroy(function)

    definition = preprocessor_formatting(function)
    file_name = filename_format(function)
    if (definition.include?(file_name))
      definition = ''
    end
    "  #{definition}\n" +
    "  #{function[:name]}_CMockResetExpectedResult();"
  end

  #
  #
  #
  #
  #
  def preprocessor_formatting(function)
    definition = function[:defs].to_s
    definition.gsub!(/\[/,'')
    definition.gsub!(/\]/,'')
    definition.gsub!(/"/,'')
    definition.gsub!(/,/,'')
    definition.gsub!(/#/,"\n#")
    definition.gsub!(/<\D*\d*>/, '')
    definition.gsub!(/\\\D*\d*\\/, '')
    definition.gsub!(/^#include\s/,'')
    definition.gsub!(/^endif/,"#endif")

    return definition
  end

  #
  #
  #
  #
  #
  def filename_format(function)

    file_name = function[:filename]
    file_name = file_name.gsub(".C",'')

    if(file_name.match("EPSGSPACECONV_INTRINSICS"))
      file_name = "_EPSGSPACECONV"
    elsif(file_name.match("D3EDITOP_INTRINSICS"))
      file_name = "D3EDITOP_INTRINISCS"
    end

    return file_name
  end

end
