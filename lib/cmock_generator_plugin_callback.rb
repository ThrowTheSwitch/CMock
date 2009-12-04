class CMockGeneratorPluginCallback

  attr_reader :priority
  attr_reader :config, :utils
  
  def initialize(config, utils)
    @config = config
    @utils = utils
    @priority = 3
  end

  def instance_structure(function)
    INSTANCE_STRUCTURE_SNIPPET % [function[:name]]
  end

  def mock_function_declarations(function)
    if (function[:args_string] == "void")
      MOCK_DECLARATION_SNIPPET % [function[:name], function[:return_type], '']
    else
      MOCK_DECLARATION_SNIPPET % [function[:name], function[:return_type], function[:args_string] + ', ']
    end
  end

  def mock_implementation(function)
    call_string = function[:args].empty? ? '' : function[:args].map{|m| m[:name]}.join(', ') + ', '
    if (function[:return_type] == 'void')
      return MOCK_IMPLEMENTATION_NORET_SNIPPET % [function[:name], call_string]
    else
      return MOCK_IMPLEMENTATION_RETVAL_SNIPPET % [function[:name], call_string]
    end
  end

  def mock_interfaces(function)
    MOCK_INTERFACE_SNIPPET % [function[:name]]
  end

  def mock_destroy(function)
    MOCK_DESTROY_SNIPPET % function[:name]
  end

  private ############

  INSTANCE_STRUCTURE_SNIPPET = %q[  CMOCK_%1$s_CALLBACK %1$s_CallbackFunctionPointer;
]

  MOCK_DECLARATION_SNIPPET = %q[
typedef %2$s (* CMOCK_%1$s_CALLBACK)(%3$sint NumCalls);
void %1$s_StubWithCallback(CMOCK_%1$s_CALLBACK Callback);
]
  
  MOCK_IMPLEMENTATION_NORET_SNIPPET = %q[
  if (Mock.%1$s_CallbackFunctionPointer != NULL)
  {
    Mock.%1$s_CallsExpected++;
    Mock.%1$s_CallbackFunctionPointer(%2$sMock.%1$s_CallCount++);
    return;
  }
]

  MOCK_IMPLEMENTATION_RETVAL_SNIPPET = %q[
  if (Mock.%1$s_CallbackFunctionPointer != NULL)
  {
    Mock.%1$s_CallsExpected++;
    return Mock.%1$s_CallbackFunctionPointer(%2$sMock.%1$s_CallCount++);
  }
]

  MOCK_INTERFACE_SNIPPET = %q[
void %1$s_StubWithCallback(CMOCK_%1$s_CALLBACK Callback)
{
  Mock.%1$s_CallbackFunctionPointer = Callback;
}
]

  MOCK_DESTROY_SNIPPET = %q[
  Mock.%1$s_CallbackFunctionPointer = NULL;
]

end
