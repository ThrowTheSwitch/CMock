
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
    call_count_type = @config.expect_call_count_type
    lines = [ "  #{call_count_type} #{function[:name]}_CallCount;\n",
              "  #{call_count_type} #{function[:name]}_CallsExpected;\n" ]
      
    if (function[:return_type] != "void")
      lines << [ "  #{function[:return_type]} *#{function[:name]}_Return;\n",
                 "  #{function[:return_type]} *#{function[:name]}_Return_Head;\n",
                 "  #{function[:return_type]} *#{function[:name]}_Return_Tail;\n" ]
    end

    if (@ordered)
      lines << [ "  int *#{function[:name]}_CallOrder;\n",
                 "  int *#{function[:name]}_CallOrder_Head;\n",
                 "  int *#{function[:name]}_CallOrder_Tail;\n" ]
    end
    
    function[:args].each do |arg|
      lines << [ "  #{arg[:type]} *#{function[:name]}_Expected_#{arg[:name]};\n",
                 "  #{arg[:type]} *#{function[:name]}_Expected_#{arg[:name]}_Head;\n",
                 "  #{arg[:type]} *#{function[:name]}_Expected_#{arg[:name]}_Tail;\n" ]
    end
    lines.flatten
  end
  
  def mock_function_declarations(function)
    if (function[:args_string] == "void")
      if (function[:return_type] == 'void')
        return ["void #{function[:name]}_Expect(void);\n"]
      else
        return ["void #{function[:name]}_ExpectAndReturn(#{function[:return_string]});\n"]
      end
    else        
      if (function[:return_type] == 'void')
        return ["void #{function[:name]}_Expect(#{function[:args_string]});\n"]
      else
        return ["void #{function[:name]}_ExpectAndReturn(#{function[:args_string]}, #{function[:return_string]});\n"]
      end
    end
  end
  
  def mock_implementation(function)
    lines = [ "  Mock.#{function[:name]}_CallCount++;\n",
              "  if (Mock.#{function[:name]}_CallCount > Mock.#{function[:name]}_CallsExpected)\n",
              "  {\n",
              "    TEST_FAIL(\"Function '#{function[:name]}' called more times than expected\");\n",
              "  }\n" ]
    
    if (@ordered)
      err_msg = "Out of order function calls. Function '#{function[:name]}'" #" expected to be call %i but was call %i"
      lines << [ "  {\n",
                 "    int* p_expected = Mock.#{function[:name]}_CallOrder;\n",
                 "    ++GlobalVerifyOrder;\n",
                 "    if (Mock.#{function[:name]}_CallOrder != Mock.#{function[:name]}_CallOrder_Tail)\n",
                 "      Mock.#{function[:name]}_CallOrder++;\n",
                 "    if ((*p_expected != GlobalVerifyOrder) && (GlobalOrderError == NULL))\n",
                 "    {\n",
                 "      const char* ErrStr = \"#{err_msg}\";\n",
                 "      GlobalOrderError = malloc(#{err_msg.size + 1});\n",
                 "      if (GlobalOrderError)\n",
                 "        strcpy(GlobalOrderError, ErrStr);\n",
                 "    }\n",
                 "  }\n" ]
    end
    
    function[:args].each do |arg|
      lines << @utils.code_verify_an_arg_expectation(function, arg[:type], arg[:name])
    end
    lines.flatten
  end
  
  def mock_interfaces(function)
    lines = []
    
    # Parameter Helper Function
    if (function[:args_string] != "void")
      lines << "void ExpectParameters_#{function[:name]}(#{function[:args_string]})\n"
      lines << "{\n"
      function[:args].each do |arg|
        lines << @utils.code_add_an_arg_expectation(function, arg[:type], arg[:name])
      end
      lines << "}\n\n"
    end
    
    #Main Mock Interface
    if (function[:return_type] == "void")
      lines << "void #{function[:name]}_Expect(#{function[:args_string]})\n"
    else
      if (function[:args_string] == "void")
        lines << "void #{function[:name]}_ExpectAndReturn(#{function[:return_string]})\n"
      else
        lines << "void #{function[:name]}_ExpectAndReturn(#{function[:args_string]}, #{function[:return_string]})\n"
      end
    end
    lines << "{\n"
    lines << @utils.code_add_base_expectation(function[:name])
    
    if (function[:args_string] != "void")
      lines << "  ExpectParameters_#{function[:name]}(#{@utils.create_call_list(function)});\n"
    end
    
    if (function[:return_type] != "void")
      lines << @utils.code_insert_item_into_expect_array(function[:return_type], "Mock.#{function[:name]}_Return_Head", 'toReturn')
      lines << "  Mock.#{function[:name]}_Return = Mock.#{function[:name]}_Return_Head;\n"
      lines << "  Mock.#{function[:name]}_Return += Mock.#{function[:name]}_CallCount;\n"
    end
    lines << "}\n\n"
  end
  
  def mock_verify(function)
    ["  TEST_ASSERT_EQUAL_MESSAGE(Mock.#{function[:name]}_CallsExpected, Mock.#{function[:name]}_CallCount, \"Function '#{function[:name]}' called unexpected number of times.\");\n"]
  end
  
  def mock_destroy(function)
    lines = []
    if (function[:return_type] != "void")
      lines << [ "  if (Mock.#{function[:name]}_Return_Head)\n",
                 "  {\n",
                 "    free(Mock.#{function[:name]}_Return_Head);\n",
                 "  }\n",
                 "  Mock.#{function[:name]}_Return=NULL;\n",
                 "  Mock.#{function[:name]}_Return_Head=NULL;\n",
                 "  Mock.#{function[:name]}_Return_Tail=NULL;\n"
               ]
    end
    if (@ordered)
      lines << [ "  if (Mock.#{function[:name]}_CallOrder_Head)\n",
                 "  {\n",
                 "    free(Mock.#{function[:name]}_CallOrder_Head);\n",
                 "  }\n",
                 "  Mock.#{function[:name]}_CallOrder=NULL;\n",
                 "  Mock.#{function[:name]}_CallOrder_Head=NULL;\n",
                 "  Mock.#{function[:name]}_CallOrder_Tail=NULL;\n"
                ]
    end
    function[:args].each do |arg|
      lines << [ "  if (Mock.#{function[:name]}_Expected_#{arg[:name]}_Head)\n",
                 "  {\n",
                 "    free(Mock.#{function[:name]}_Expected_#{arg[:name]}_Head);\n",
                 "  }\n",
                 "  Mock.#{function[:name]}_Expected_#{arg[:name]}=NULL;\n",
                 "  Mock.#{function[:name]}_Expected_#{arg[:name]}_Head=NULL;\n",
                 "  Mock.#{function[:name]}_Expected_#{arg[:name]}_Tail=NULL;\n"
               ]
    end
    lines.flatten
  end
end
