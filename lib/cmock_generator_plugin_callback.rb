class CMockGeneratorPluginCallback

  attr_reader :priority
  attr_reader :config, :utils
  
  def initialize(config, utils)
    @config = config
    @utils = utils
    @priority = 3
  end

  def instance_structure(function)
    func_name = function[:name]
    "  CMOCK_#{func_name}_CALLBACK #{func_name}_CallbackFunctionPointer;\n" +
    "  int #{func_name}_CallbackCalls;\n"
  end

  def mock_function_declarations(function)
    func_name = function[:name]
    "typedef #{function[:return][:type]} (* CMOCK_#{func_name}_CALLBACK)(#{(function[:args_string] == "void") ? '' : function[:args_string] + ', '}int cmock_num_calls);\n" +
    "void #{func_name}_StubWithCallback(CMOCK_#{func_name}_CALLBACK Callback);\n"
  end

  def mock_implementation_precheck(function)
    func_name   = function[:name]
    call_string = function[:args].empty? ? '' : function[:args].map{|m| m[:name]}.join(', ') + ', '
    "  if (Mock.#{func_name}_CallbackFunctionPointer != NULL)\n  {\n" +
    if (function[:return][:void?])
      "    Mock.#{func_name}_CallbackFunctionPointer(#{call_string}Mock.#{func_name}_CallbackCalls++);\n    return;\n  }\n"
    else
      "    return Mock.#{func_name}_CallbackFunctionPointer(#{call_string}Mock.#{func_name}_CallbackCalls++);\n  }\n"
    end
  end

  def mock_interfaces(function)
    func_name = function[:name]
    "void #{func_name}_StubWithCallback(CMOCK_#{func_name}_CALLBACK Callback)\n{\n" + 
    "  Mock.#{func_name}_CallbackFunctionPointer = Callback;\n}\n\n"
  end

  def mock_destroy(function)
    "  Mock.#{function[:name]}_CallbackFunctionPointer = NULL;\n" +
    "  Mock.#{function[:name]}_CallbackCalls = 0;\n"
  end
  
  def mock_verify(function)
    func_name = function[:name]
    "  if (Mock.#{func_name}_CallbackFunctionPointer != NULL)\n    Mock.#{func_name}_CallInstance = NULL;\n"
  end

end
