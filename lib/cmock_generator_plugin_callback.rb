# ==========================================
#   CMock Project - Automatic Mock Generation for C
#   Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
#   [Released under MIT License. Please refer to license.txt for details]
# ==========================================

class CMockGeneratorPluginCallback

  attr_accessor :include_count
  attr_reader :priority
  attr_reader :config, :utils

  def initialize(config, utils)
    @config = config
    @utils = utils
    @priority = 6

    @include_count = @config.callback_include_count
    if (@config.callback_after_arg_check)
      alias :mock_implementation          :mock_implementation_for_callbacks_after_arg_check
      alias :mock_implementation_precheck :nothing
    else
      alias :mock_implementation_precheck :mock_implementation_for_callbacks_without_arg_check
      alias :mock_implementation          :nothing
    end
  end

  def instance_structure(function)
    func_name = function[:name]
    "  CMOCK_#{func_name}_CALLBACK #{func_name}_CallbackFunctionPointer;\n" +
    "  int #{func_name}_CallbackCalls;\n"
  end

  def mock_function_declarations(function)
    func_name = function[:name]
    return_type = function[:return][:type]
    style  = (@include_count ? 1 : 0) | (function[:args].empty? ? 0 : 2)
    styles = [ "void", "int cmock_num_calls", function[:args_string], "#{function[:args_string]}, int cmock_num_calls" ]
    "typedef #{return_type} (* CMOCK_#{func_name}_CALLBACK)(#{styles[style]});\nvoid #{func_name}_StubWithCallback(CMOCK_#{func_name}_CALLBACK Callback);\n"
  end

  def generate_call(function)
    args = function[:args].map { |m| m[:name] }
    args << "Mock.#{function[:name]}_CallbackCalls++" if @include_count
    "Mock.#{function[:name]}_CallbackFunctionPointer(#{args.join(', ')})"
  end

  def mock_implementation_for_callbacks_after_arg_check(function)
    "  if (Mock.#{function[:name]}_CallbackFunctionPointer != NULL)\n  {\n" +
      if function[:return][:void?]
        "    #{generate_call(function)};\n  }\n"
      else
        "    cmock_call_instance->ReturnVal = #{generate_call(function)};\n  }\n"
      end
  end

  def mock_implementation_for_callbacks_without_arg_check(function)
    "  if (Mock.#{function[:name]}_CallbackFunctionPointer != NULL)\n  {\n" +
      if function[:return][:void?]
        "    #{generate_call(function)};\n" \
        "    UNITY_CLR_DETAILS();\n" \
        "    return;\n  }\n"
      else
        "    #{function[:return][:type]} ret = #{generate_call(function)};\n" \
        "    UNITY_CLR_DETAILS();\n" \
        "    return ret;\n  }\n"
      end
  end

  def nothing(function)
    return ""
  end

  def mock_interfaces(function)
    func_name = function[:name]
    lines = ""
    lines << "void #{func_name}_StubWithCallback(CMOCK_#{func_name}_CALLBACK Callback)\n{\n"
    if @config.plugins.include? :ignore
      lines << "  Mock.#{func_name}_IgnoreBool = (int)0;\n"
    end
    lines << "  Mock.#{func_name}_CallbackFunctionPointer = Callback;\n}\n\n"
  end

  def mock_destroy(function)
    "  Mock.#{function[:name]}_CallbackFunctionPointer = NULL;\n" +
    "  Mock.#{function[:name]}_CallbackCalls = 0;\n"
  end

  def mock_verify(function)
    func_name = function[:name]
    "  if (Mock.#{func_name}_CallbackFunctionPointer != NULL)\n    call_instance = CMOCK_GUTS_NONE;\n"
  end

end
