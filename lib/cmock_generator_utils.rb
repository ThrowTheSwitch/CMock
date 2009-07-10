
class CMockGeneratorUtils

  attr_accessor :config, :helpers, :ordered

  def initialize(config, helpers={})
    @config = config
    @ptr_handling = @config.when_ptr_star
    @ordered = @config.enforce_strict_ordering
	  @helpers = helpers
  end
  
  def create_call_list(function)
    call_list = ""
    function[:args].each do |arg|
      if call_list.empty?
        call_list = arg[:name]
      else
        call_list += ", " + arg[:name]
      end
    end
    return call_list
  end
  
  def code_insert_item_into_expect_array(type, array, newValue)
    INSERT_EXPECT_CODE_SNIPPET % [type, array, newValue]
  end
  
  def code_add_an_arg_expectation(function, arg_type, expected)
    var = "Mock.#{function[:name]}_Expected_#{expected}"
    lines = code_insert_item_into_expect_array(arg_type, var, expected)
    lines << INSERT_EXPECT_SETUP_SNIPPET % [var, function[:name]]
  end
  
  def code_add_base_expectation(func_name)
    lines = "  Mock.#{func_name}_CallsExpected++;\n"
    if (@ordered)
      var = "Mock.#{func_name}_CallOrder"
      lines << "  ++GlobalExpectCount;\n"
      lines << code_insert_item_into_expect_array('int', var, 'GlobalExpectCount')
      lines << INSERT_EXPECT_SETUP_SNIPPET % [var, func_name]
    end
    lines
  end
  
  def code_verify_an_arg_expectation(function, arg_type, arg) 
    (INSERT_ARG_VERIFY_START_SNIPPET % ["#{function[:name]}_Expected_#{arg}", arg_type]) +
    expect_helper(arg_type, '*p_expected', arg, "\"Function '#{function[:name]}' called with unexpected value for argument '#{arg}'.\"") +
    "  }\n" 
  end
  
  def expect_helper(c_type, expected, arg, msg)
    if ((c_type.strip[-1] == 42) and (@ptr_handling == :compare_ptr))
      unity_func = "TEST_ASSERT_EQUAL_INT_MESSAGE"
    else
      unity_func = (@helpers.nil? or @helpers[:unity_helper].nil?) ? "TEST_ASSERT_EQUAL_MESSAGE" : @helpers[:unity_helper].get_helper(c_type)
    end
    unity_msg  = (unity_func =~ /_MESSAGE/) ? ", #{msg}" : ''
    case(unity_func)
      when "TEST_ASSERT_EQUAL_MEMORY_MESSAGE"
        full_expected = (expected =~ /^\*/) ? expected.slice(1..-1) : "&(#{expected})"
        return "    #{unity_func}((void*)#{full_expected}, (void*)&(#{arg}), sizeof(#{c_type})#{unity_msg});\n"  
      when /_ARRAY/
        return "    if (*p_expected == NULL)\n      { TEST_ASSERT_NULL(#{arg}); }\n    else\n      { #{unity_func}(#{expected}, #{arg}, 1#{unity_msg}); }\n"
      else
        return "    #{unity_func}(#{expected}, #{arg}#{unity_msg});\n" 
    end  
  end
  
  def code_handle_return_value(function)
    INSERT_RETURN_TYPE_SNIPPET % [ function[:name], function[:return_type] ]
  end
  
  private ###################
  
  INSERT_EXPECT_CODE_SNIPPET = %q[
  {
    int sz = 0;
    %1$s *pointer = %2$s_Head;
    while (pointer && pointer != %2$s_Tail) { sz++; pointer++; }
    if (sz == 0)
    {
      %2$s_Head = (%1$s*)malloc(2*sizeof(%1$s));
      if (!%2$s_Head)
        Mock.allocFailure++;
    }
    else
    {
      %1$s *ptmp = (%1$s*)realloc(%2$s_Head, sizeof(%1$s) * (sz+1));
      if (!ptmp)
        Mock.allocFailure++;
      else
        %2$s_Head = ptmp;
    }
    memcpy(&%2$s_Head[sz], &%3$s, sizeof(%1$s));
    %2$s_Tail = &%2$s_Head[sz+1];
  }
]
 
  INSERT_EXPECT_SETUP_SNIPPET = 
  "  %1$s = %1$s_Head;\n  %1$s += Mock.%2$s_CallCount;\n"
  
  INSERT_RETURN_TYPE_SNIPPET = %q[
  if (Mock.%1$s_Return != Mock.%1$s_Return_Tail)
  {
    %2$s toReturn = *Mock.%1$s_Return;
    Mock.%1$s_Return++;
    return toReturn;
  }
  else
  {
    return *(Mock.%1$s_Return_Tail - 1);
  }
]

  INSERT_ARG_VERIFY_START_SNIPPET = %q[
  if (Mock.%1$s != Mock.%1$s_Tail)
  {
    %2$s* p_expected = Mock.%1$s;
    Mock.%1$s++;
]

end