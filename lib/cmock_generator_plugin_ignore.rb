
class CMockGeneratorPluginIgnore

  attr_reader :config, :utils
  
  def initialize(config, utils)
    @config = config
    @utils = utils
  end
  
  def instance_structure(function)
    return "  int #{function[:name]}_IgnoreBool;\n"
  end
  
  def mock_function_declarations(function)
    if (function[:return_type] == "void")
      return "void #{function[:name]}_Ignore(void);\n"
    else        
      return "void #{function[:name]}_IgnoreAndReturn(#{function[:return_string]});\n"
    end 
  end
  
  def mock_implementation_prefix(function)
    lines = "  if (Mock.#{function[:name]}_IgnoreBool)\n  {" 
    if (function[:return_type] == "void")
      lines << "\n    return;\n"
    else
      lines << MOCK_IMPLEMENT_PREFIX_SNIPPET % [function[:name], function[:return_type]]
    end
    lines << "  }\n"
  end
  
  def mock_interfaces(function)
    if (function[:return_type] == "void")
      MOCK_INTERFACE_VOID_SNIPPET % function[:name]
    else
      item_insert = @utils.code_insert_item_into_expect_array(function[:return_type], "Mock.#{function[:name]}_Return", 'toReturn')
      MOCK_INTERFACE_FULL_SNIPPET % [function[:name], function[:return_string], item_insert]
    end
  end
  
  private ##############
  
  MOCK_IMPLEMENT_PREFIX_SNIPPET = %q[
    if (Mock.%1$s_Return != Mock.%1$s_Return_Tail)
    {
      %2$s toReturn = *Mock.%1$s_Return;
      Mock.%1$s_Return++;
      Mock.%1$s_CallCount++;
      Mock.%1$s_CallsExpected++;
      return toReturn;
    }
    else
    {
      return *(Mock.%1$s_Return_Tail - 1);
    }
]

  MOCK_INTERFACE_VOID_SNIPPET = %q[
void %1$s_Ignore(void)
{
  Mock.%1$s_IgnoreBool = (int)1;
}

]

  MOCK_INTERFACE_FULL_SNIPPET = %q[
void %1$s_IgnoreAndReturn(%2$s)
{
  Mock.%1$s_IgnoreBool = (int)1;
%3$s
  Mock.%1$s_Return = Mock.%1$s_Return_Head;
  Mock.%1$s_Return += Mock.%1$s_CallCount;
}

]

end
