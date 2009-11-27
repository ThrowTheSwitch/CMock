
class CMockGeneratorUtils

  attr_accessor :config, :helpers, :ordered

  def initialize(config, helpers={})
    @config = config
    @ptr_handling = @config.when_ptr_star
    @ordered = @config.enforce_strict_ordering
    @arrays  = @config.plugins.include? :array
	  @helpers = helpers
  end
  
  def code_insert_item_into_expect_array(type, array, newValue)
    INSERT_EXPECT_CODE_SNIPPET % [type, array, newValue]
  end
  
  def code_add_an_arg_expectation(function, arg, depth=1)
    var = "Mock.#{function[:name]}_Expected_#{arg[:name]}"
    lines = code_insert_item_into_expect_array(arg[:type], var, arg[:name])
    lines << INSERT_EXPECT_SETUP_SNIPPET % [var, function[:name]]
    if (@arrays and arg[:ptr?])
      var += '_Depth'
      lines << INSERT_EXPECT_SHORT_CODE_SNIPPET % ['int', var, depth]
      lines << INSERT_EXPECT_SETUP_SNIPPET % [var, function[:name]]
    end
    lines
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
  
  def code_verify_an_arg_expectation(function, arg) 
    (INSERT_ARG_VERIFY_START_SNIPPET % ["#{function[:name]}_Expected_#{arg[:name]}", arg[:type]]) +
    expect_helper(arg, '*p_expected', "\"Function '#{function[:name]}' called with unexpected value for argument '#{arg[:name]}'.\"", "#{function[:name]}_Expected_#{arg[:name]}_Depth") +
    "\n  }\n" 
  end
  
  def expect_helper(arg, expected, msg, depth_name='1')
    c_type = arg[:type]
    name   = arg[:name]
    if ((arg[:ptr?]) and (@ptr_handling == :compare_ptr))
      unity_func = "TEST_ASSERT_EQUAL_INT_MESSAGE"
    else
      unity_func = (@helpers.nil? or @helpers[:unity_helper].nil?) ? "TEST_ASSERT_EQUAL_MESSAGE" : @helpers[:unity_helper].get_helper(c_type)
    end
    unity_msg  = (unity_func =~ /_MESSAGE/) ? ", #{msg}" : ''
    case(unity_func)
      when "TEST_ASSERT_EQUAL_MEMORY_MESSAGE"
        full_expected = (expected =~ /^\*/) ? expected.slice(1..-1) : "&(#{expected})"
        return "    TEST_ASSERT_EQUAL_MEMORY_MESSAGE((void*)#{full_expected}, (void*)&(#{name}), sizeof(#{c_type})#{unity_msg});\n"
      when "TEST_ASSERT_EQUAL_MEMORY_MESSAGE_ARRAY"
        if (@arrays)
          [ (INSERT_ARG_DEPTH_START_SNIPPET % [depth_name]),
            "    if (*p_expected == NULL)",
            "      { TEST_ASSERT_NULL(#{name}); }",
            "    else",
            "      { TEST_ASSERT_EQUAL_MEMORY_ARRAY_MESSAGE((void*)(#{expected}), (void*)#{name}, sizeof(#{c_type.sub('*','')}), Depth#{unity_msg}); }"].join("\n")
        else
          [ "    if (*p_expected == NULL)",
            "      { TEST_ASSERT_NULL(#{name}); }",
            "    else",
            "      { TEST_ASSERT_EQUAL_MEMORY_MESSAGE((void*)(#{expected}), (void*)#{name}, sizeof(#{c_type.sub('*','')})#{unity_msg}); }"].join("\n")

        end
      when /_ARRAY/
        if (@arrays)
          [ (INSERT_ARG_DEPTH_START_SNIPPET % ["#{function[:name]}_Expected_#{name}_Depth"]),
            "    if (*p_expected == NULL)",
            "      { TEST_ASSERT_NULL(#{name}); }",
            "    else",
            "      { #{unity_func}(#{expected}, #{name}, Depth); }"].join("\n")
        else
          [ "    if (*p_expected == NULL)",
            "      { TEST_ASSERT_NULL(#{name}); }",
            "    else",
            "      { #{unity_func}(#{expected}, #{name}, 1); }"].join("\n")
        end
      else
        return "    #{unity_func}(#{expected}, #{name}#{unity_msg});\n" 
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
 
  INSERT_EXPECT_SHORT_CODE_SNIPPET = %q[
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
    %2$s_Head[sz] = %3$s;
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

  INSERT_ARG_DEPTH_START_SNIPPET = %q[
    int Depth = *Mock.%1$s;
    Mock.%1$s++;
]

end