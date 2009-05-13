
class CMockGeneratorUtils

  attr_accessor :config, :tab, :helpers, :ordered

  def initialize(config, helpers={})
    @config = config
	  @tab = @config.tab
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
    tail = array.gsub(/Head$/,'Tail')
    lines = ["\n"]
    lines << "#{@tab}{\n"
    lines << "#{@tab}#{@tab}int sz = 0;\n"
    lines << "#{@tab}#{@tab}#{type} *pointer = #{array};\n"
    lines << "#{@tab}#{@tab}while (pointer && pointer != #{tail}) { sz++; pointer++; }\n"
    lines << "#{@tab}#{@tab}if (sz == 0)\n"
    lines << "#{@tab}#{@tab}{\n"
    lines << "#{@tab}#{@tab}#{@tab}#{array} = (#{type}*)malloc(2*sizeof(#{type}));\n"
    lines << "#{@tab}#{@tab}#{@tab}if (!#{array})\n"
    lines << "#{@tab}#{@tab}#{@tab}#{@tab}Mock.allocFailure++;\n"
    lines << "#{@tab}#{@tab}}\n"
    lines << "#{@tab}#{@tab}else\n"
    lines << "#{@tab}#{@tab}{\n"
    lines << "#{@tab}#{@tab}#{@tab}#{type} *ptmp = (#{type}*)realloc(#{array}, sizeof(#{type}) * (sz+1));\n"
    lines << "#{@tab}#{@tab}#{@tab}if (!ptmp)\n"
    lines << "#{@tab}#{@tab}#{@tab}#{@tab}Mock.allocFailure++;\n"
    lines << "#{@tab}#{@tab}#{@tab}else\n"
    lines << "#{@tab}#{@tab}#{@tab}#{@tab}#{array} = ptmp;\n"
    lines << "#{@tab}#{@tab}}\n"
    lines << "#{@tab}#{@tab}memcpy(&#{array}[sz], &#{newValue}, sizeof(#{type}));\n"
    lines << "#{@tab}#{@tab}#{tail} = &#{array}[sz+1];\n"
    lines << "#{@tab}}\n"
  end
  
  def code_add_an_arg_expectation(function, arg_type, expected)
    lines = code_insert_item_into_expect_array(arg_type, "Mock.#{function[:name]}_Expected_#{expected}_Head", expected)
    lines << "#{@tab}Mock.#{function[:name]}_Expected_#{expected} = Mock.#{function[:name]}_Expected_#{expected}_Head;\n"
    lines << "#{@tab}Mock.#{function[:name]}_Expected_#{expected} += Mock.#{function[:name]}_CallCount;\n"
  end
  
  def code_add_base_expectation(func_name)
    lines = ["#{@tab}Mock.#{func_name}_CallsExpected++;\n"]
    if (@ordered)
      lines << [ "#{@tab}++GlobalExpectCount;\n",
                 code_insert_item_into_expect_array("int", "Mock.#{func_name}_CallOrder_Head", "GlobalExpectCount"),
                 "#{@tab}Mock.#{func_name}_CallOrder = Mock.#{func_name}_CallOrder_Head;\n",
                 "#{@tab}Mock.#{func_name}_CallOrder += Mock.#{func_name}_CallOrder;\n" ]
    end
    lines.flatten
  end
  
  def code_verify_an_arg_expectation(function, arg_type, actual)
    [ "\n",
      "#{@tab}if (Mock.#{function[:name]}_Expected_#{actual} != Mock.#{function[:name]}_Expected_#{actual}_Tail)\n",
      "#{@tab}{\n",
      "#{@tab}#{@tab}#{arg_type}* p_expected = Mock.#{function[:name]}_Expected_#{actual};\n",
      "#{@tab}#{@tab}Mock.#{function[:name]}_Expected_#{actual}++;\n",
      expect_helper(arg_type, '*p_expected', actual, "\"Function '#{function[:name]}' called with unexpected value for argument '#{actual}'.\"","#{@tab}#{@tab}"),
      "#{@tab}}\n" ].flatten
  end
  
  def expect_helper(c_type, expected, actual, msg, indent)
    if ((c_type.strip[-1] == 42) and (@ptr_handling == :compare_ptr))
      unity_func = "TEST_ASSERT_EQUAL_INT_MESSAGE"
    else
      unity_func = (@helpers.nil? or @helpers[:unity_helper].nil?) ? "TEST_ASSERT_EQUAL_MESSAGE" : @helpers[:unity_helper].get_helper(c_type)
    end
    unity_msg  = (unity_func =~ /_MESSAGE/) ? ", #{msg}" : ''
    case(unity_func)
      when "TEST_ASSERT_EQUAL_MEMORY_MESSAGE"
        full_expected = (expected.strip[0] == 42) ? expected.slice(1..-1) : "&(#{expected})"
        return "#{indent}#{unity_func}((void*)#{full_expected}, (void*)&(#{actual}), sizeof(#{c_type})#{unity_msg});\n"  
      when /_ARRAY/
        return [ "#{indent}if (*p_expected == NULL)\n",
                 "#{indent}#{@tab}{ TEST_ASSERT_NULL(#{actual}); }\n",
                 "#{indent}else\n",
                 "#{indent}#{@tab}{ #{unity_func}(#{expected}, #{actual}, 1#{unity_msg}); }\n" ]
      else
        return "#{indent}#{unity_func}(#{expected}, #{actual}#{unity_msg});\n" 
    end  
  end

  def code_handle_return_value(function, indent)
    [ "\n",
      "#{indent}if (Mock.#{function[:name]}_Return != Mock.#{function[:name]}_Return_Tail)\n",
      "#{indent}{\n",
      "#{indent}#{@tab}#{function[:rettype]} toReturn = *Mock.#{function[:name]}_Return;\n",
      "#{indent}#{@tab}Mock.#{function[:name]}_Return++;\n",
      "#{indent}#{@tab}return toReturn;\n",
      "#{indent}}\n",
      "#{indent}else\n",
      "#{indent}{\n",
      "#{indent}#{@tab}return *Mock.#{function[:name]}_Return_Head;\n",
      "#{indent}}\n" ]
  end
end