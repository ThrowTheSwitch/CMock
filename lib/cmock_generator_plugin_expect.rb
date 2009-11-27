
class CMockGeneratorPluginExpect

  attr_accessor :config, :utils, :unity_helper, :ordered

  def initialize(config, utils)
    @config       = config
    @ptr_handling = @config.when_ptr_star
    @ordered      = @config.enforce_strict_ordering
    @utils        = utils
    @unity_helper = @utils.helpers[:unity_helper]
  end
  
  def instance_structure(function)
    lines = INSTANCE_STRUCTURE_CALL_SNIPPET % function[:name]
    
    if (function[:return_type] != "void")
      lines << INSTANCE_STRUCTURE_ITEM_SNIPPET % "#{function[:return_type]} *#{function[:name]}_Return"
    end
    
    if (@ordered)
      lines << INSTANCE_STRUCTURE_ITEM_SNIPPET % "int *#{function[:name]}_CallOrder"
    end
    
    function[:args].each do |arg|
      lines << INSTANCE_STRUCTURE_ITEM_SNIPPET % "#{arg[:type]} *#{function[:name]}_Expected_#{arg[:name]}"
    end
    lines
  end
  
  def mock_function_declarations(function)
    if (function[:args_string] == "void")
      if (function[:return_type] == 'void')
        return "void #{function[:name]}_Expect(void);\n"
      else
        return "void #{function[:name]}_ExpectAndReturn(#{function[:return_string]});\n"
      end
    else        
      if (function[:return_type] == 'void')
        return "void #{function[:name]}_Expect(#{function[:args_string]});\n"
      else
        return "void #{function[:name]}_ExpectAndReturn(#{function[:args_string]}, #{function[:return_string]});\n"
      end
    end
  end
  
  def mock_implementation(function)
    lines = MOCK_IMPLEMENT_SNIPPET % function[:name]
    if (@ordered)
      err_msg = "Out of order function calls. Function '#{function[:name]}'" #would eventually like to be " expected to be call %i but was call %i"
      lines << MOCK_IMPLEMENT_ORDERED_SNIPPET % [function[:name], err_msg, (err_msg.size + 1).to_s]
    end
    function[:args].each do |arg|
      lines << @utils.code_verify_an_arg_expectation(function, arg)
    end
    lines
  end
  
  def mock_interfaces(function)
    lines = []
    func_name = function[:name]
    
    # Parameter Helper Function
    if (function[:args_string] != "void")
      lines << "void ExpectParameters_#{func_name}(#{function[:args_string]})\n{\n"
      function[:args].each do |arg|
        lines << @utils.code_add_an_arg_expectation(function, arg)
      end
      lines << "}\n\n"
    end
    
    #Main Mock Interface
    if (function[:return_type] == "void")
      lines << "void #{func_name}_Expect(#{function[:args_string]})\n"
    else
      if (function[:args_string] == "void")
        lines << "void #{func_name}_ExpectAndReturn(#{function[:return_string]})\n"
      else
        lines << "void #{func_name}_ExpectAndReturn(#{function[:args_string]}, #{function[:return_string]})\n"
      end
    end
    lines << "{\n"
    lines << @utils.code_add_base_expectation(func_name)
    
    if (function[:args_string] != "void")
      lines << "  ExpectParameters_#{func_name}(#{function[:args].map{|m| m[:name]}.join(', ')});\n"
    end
    
    if (function[:return_type] != "void")
      lines << @utils.code_insert_item_into_expect_array(function[:return_type], "Mock.#{func_name}_Return", 'toReturn')
      lines << "  Mock.#{func_name}_Return = Mock.#{func_name}_Return_Head;\n"
      lines << "  Mock.#{func_name}_Return += Mock.#{func_name}_CallCount;\n"
    end
    lines << "}\n\n"
  end
  
  def mock_verify(function)
    func_name = function[:name]
    "  TEST_ASSERT_EQUAL_MESSAGE(Mock.#{func_name}_CallsExpected, Mock.#{func_name}_CallCount, \"Function '#{func_name}' called unexpected number of times.\");\n"
  end
  
  def mock_destroy(function)
    lines = []
    func_name = function[:name]
    if (function[:return_type] != "void")
      lines << DESTROY_RETURN_SNIPPET % func_name
    end
    
    if (@ordered)
      lines << DESTROY_CALL_ORDER_SNIPPET % func_name
    end
    
    function[:args].each do |arg|
      lines << DESTROY_BASE_SNIPPET % "#{func_name}_Expected_#{arg[:name]}"
    end
    lines.flatten
  end
  
  private #####################
  
  INSTANCE_STRUCTURE_CALL_SNIPPET = %q[
  int %1$s_CallCount;
  int %1$s_CallsExpected;
]

  INSTANCE_STRUCTURE_ITEM_SNIPPET = %q[
  %1$s;
  %1$s_Head;
  %1$s_Tail;
]

  MOCK_IMPLEMENT_SNIPPET = %q[
  Mock.%1$s_CallCount++;
  if (Mock.%1$s_CallCount > Mock.%1$s_CallsExpected)
  {
    TEST_FAIL("Function '%1$s' called more times than expected");
  }
]

  MOCK_IMPLEMENT_ORDERED_SNIPPET = %q[  {
    int* p_expected = Mock.%1$s_CallOrder;
    ++GlobalVerifyOrder;
    if (Mock.%1$s_CallOrder != Mock.%1$s_CallOrder_Tail)
      Mock.%1$s_CallOrder++;
    if ((*p_expected != GlobalVerifyOrder) && (GlobalOrderError == NULL))
    {
      const char* ErrStr = "%2$s";
      GlobalOrderError = malloc(%3$s);
      if (GlobalOrderError)
        strcpy(GlobalOrderError, ErrStr);
    }
  }
]

  DESTROY_RETURN_SNIPPET = %q[
  if (Mock.%1$s_Return_Head)
  {
    free(Mock.%1$s_Return_Head);
  }
  Mock.%1$s_Return=NULL;
  Mock.%1$s_Return_Head=NULL;
  Mock.%1$s_Return_Tail=NULL;
]

  DESTROY_CALL_ORDER_SNIPPET = %q[
  if (Mock.%1$s_CallOrder_Head)
  {
    free(Mock.%1$s_CallOrder_Head);
  }
  Mock.%1$s_CallOrder=NULL;
  Mock.%1$s_CallOrder_Head=NULL;
  Mock.%1$s_CallOrder_Tail=NULL;
]

  DESTROY_BASE_SNIPPET = %q[
  if (Mock.%1$s_Head)
  {
    free(Mock.%1$s_Head);
  }
  Mock.%1$s=NULL;
  Mock.%1$s_Head=NULL;
  Mock.%1$s_Tail=NULL;
]
  
end
