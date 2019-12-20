# ==========================================
#   CMock Project - Automatic Mock Generation for C
#   Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
#   [Released under MIT License. Please refer to license.txt for details]
# ==========================================

class CMockGeneratorPluginIgnore

  attr_reader :priority
  attr_reader :config, :utils

  def initialize(config, utils)
    @config = config
    @utils = utils
    @priority = 2
  end

  def instance_structure(function)
    if (function[:return][:void?])
      "  int #{function[:scoped_name]}_IgnoreBool;\n"
    elsif function[:return][:type].end_with?('&')
      "  int #{function[:scoped_name]}_IgnoreBool;\n  #{function[:return][:type].chomp('&')} #{function[:scoped_name]}_FinalRefReturn;\n  std::reference_wrapper<#{function[:return][:type].chomp('&')}> #{function[:scoped_name]}_FinalReturn = #{function[:scoped_name]}_FinalRefReturn;\n"
    else
      "  int #{function[:scoped_name]}_IgnoreBool;\n  #{function[:return][:type]} #{function[:scoped_name]}_FinalReturn;\n"
    end
  end

  def mock_function_declarations(function)
    if (function[:return][:void?])
      return "#define #{function[:scoped_name]}_Ignore() #{function[:scoped_name]}_CMockIgnore()\n" +
             "void #{function[:scoped_name]}_CMockIgnore(void);\n"
    else
      return "#define #{function[:scoped_name]}_IgnoreAndReturn(cmock_retval) #{function[:scoped_name]}_CMockIgnoreAndReturn(__LINE__, cmock_retval)\n" +
             "void #{function[:scoped_name]}_CMockIgnoreAndReturn(UNITY_LINE_TYPE cmock_line, #{function[:return][:str]});\n"
    end
  end

  def mock_implementation_precheck(function)
    lines = "  if (Mock.#{function[:scoped_name]}_IgnoreBool)\n  {\n"
    lines << "    UNITY_CLR_DETAILS();\n"
    if (function[:return][:void?])
      lines << "    return;\n  }\n"
    else
      retval = function[:return].merge( { :name => "cmock_call_instance->ReturnVal"} )
      lines << "    if (cmock_call_instance == NULL)\n      return Mock.#{function[:scoped_name]}_FinalReturn;\n"
      lines << "  " + @utils.code_assign_argument_quickly("Mock.#{function[:scoped_name]}_FinalReturn", retval) unless (retval[:void?])
      lines << "    return cmock_call_instance->ReturnVal;\n  }\n"
    end
    lines
  end

  def mock_interfaces(function)
    lines = ""
    if (function[:return][:void?])
      lines << "void #{function[:scoped_name]}_CMockIgnore(void)\n{\n"
    else
      lines << "void #{function[:scoped_name]}_CMockIgnoreAndReturn(UNITY_LINE_TYPE cmock_line, #{function[:return][:str]})\n{\n"
    end
    if (!function[:return][:void?])
      lines << @utils.code_add_base_expectation(function[:scoped_name], false)
    end
    unless (function[:return][:void?])
      lines << "  cmock_call_instance->ReturnVal = cmock_to_return;\n"
    end
    lines << "  Mock.#{function[:scoped_name]}_IgnoreBool = (int)1;\n"
    lines << "}\n\n"
  end

  def mock_ignore(function)
    "  Mock.#{function[:scoped_name]}_IgnoreBool = (int) 1;\n"
  end

  def mock_verify(function)
    func_name = function[:scoped_name]
    "  if (Mock.#{func_name}_IgnoreBool)\n    call_instance = CMOCK_GUTS_NONE;\n"
  end
end
