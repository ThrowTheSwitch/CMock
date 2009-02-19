
class CMockGeneratorUtils

  attr_accessor :config, :tab, :helpers

  def initialize(config, helpers={})
    @config = config
	  @tab = @config.tab
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
    lines = ["\n"]
    lines << "#{@tab}{\n"
    lines << "#{@tab}#{@tab}int sz = 0;\n"
    lines << "#{@tab}#{@tab}#{type} *pointer = #{array};\n"
    lines << "#{@tab}#{@tab}while(pointer && pointer != #{array}Tail) { sz++; pointer++; }\n"
    lines << "#{@tab}#{@tab}if(sz == 0)\n"
    lines << "#{@tab}#{@tab}{\n"
    lines << "#{@tab}#{@tab}#{@tab}#{array} = (#{type}*)malloc(2*sizeof(#{type}));\n"
    lines << "#{@tab}#{@tab}#{@tab}if(!#{array})\n"
    lines << "#{@tab}#{@tab}#{@tab}#{@tab}Mock.allocFailure++;\n"
    lines << "#{@tab}#{@tab}}\n"
    lines << "#{@tab}#{@tab}else\n"
    lines << "#{@tab}#{@tab}{\n"
    lines << "#{@tab}#{@tab}#{@tab}#{type} *ptmp = (#{type}*)realloc(#{array}, sizeof(#{type}) * (sz+1));\n"
    lines << "#{@tab}#{@tab}#{@tab}if(!ptmp)\n"
    lines << "#{@tab}#{@tab}#{@tab}#{@tab}Mock.allocFailure++;\n"
    lines << "#{@tab}#{@tab}#{@tab}else\n"
    lines << "#{@tab}#{@tab}#{@tab}#{@tab}#{array} = ptmp;\n"
    lines << "#{@tab}#{@tab}}\n"
    lines << "#{@tab}#{@tab}memcpy(&#{array}[sz], &#{newValue}, sizeof(#{type}));\n"
    lines << "#{@tab}#{@tab}#{array}Tail = &#{array}[sz+1];\n"
    lines << "#{@tab}}\n"
  end
  
  def code_handle_return_value(function, indent)
    lines = ["\n"]
    lines << "#{indent}#{function[:rettype]} toReturn;\n"
    lines << "#{indent}if (Mock.#{function[:name]}_Return != Mock.#{function[:name]}_Return_HeadTail)\n"
    lines << "#{indent}{\n"
    lines << "#{indent}#{@tab}memcpy(&toReturn, Mock.#{function[:name]}_Return, sizeof(#{function[:rettype]}));\n"
    lines << "#{indent}#{@tab}Mock.#{function[:name]}_Return++;\n"
    lines << "#{indent}}\n"
    lines << "#{indent}else\n"
    lines << "#{indent}{\n"
    lines << "#{indent}#{@tab}memcpy(&toReturn, Mock.#{function[:name]}_Return_Head, sizeof(#{function[:rettype]}));\n"
    lines << "#{indent}}\n"
    lines << "#{indent}return toReturn;\n"
  end
  
  def code_add_an_arg_expectation(function, arg_type, expected)
    lines = code_insert_item_into_expect_array(arg_type, "Mock.#{function[:name]}_Expected_#{expected}_Head", expected)
    lines << "#{@tab}Mock.#{function[:name]}_Expected_#{expected} = Mock.#{function[:name]}_Expected_#{expected}_Head;\n"
    lines << "#{@tab}Mock.#{function[:name]}_Expected_#{expected} += Mock.#{function[:name]}_CallCount;\n"
  end
  
  def code_verify_an_arg_expectation(function, arg_type, actual)
    expect = expect_helper(arg_type, '*p_expected', actual, "\"Function '#{function[:name]}' called with unexpected value for parameter '#{actual}'.\"")
    lines = ["\n"]
    lines << "#{@tab}if (Mock.#{function[:name]}_Expected_#{actual} != Mock.#{function[:name]}_Expected_#{actual}_HeadTail)\n"
    lines << "#{@tab}{\n"
    lines << "#{@tab}#{@tab}#{arg_type}* p_expected = Mock.#{function[:name]}_Expected_#{actual};\n"
    lines << "#{@tab}#{@tab}Mock.#{function[:name]}_Expected_#{actual}++;\n"
    lines << "#{@tab}#{@tab}#{expect};\n"
    lines << "#{@tab}}\n"
  end
  
  def expect_helper(c_type, expected, actual, msg)
    unity_func = (@helpers.nil? or @helpers[:unity_helper].nil?) ? "TEST_ASSERT_EQUAL_MESSAGE" : @helpers[:unity_helper].get_helper(c_type)
    unity_msg  = (unity_func =~ /_MESSAGE/) ? ", #{msg}" : ''
    if (unity_func == "TEST_ASSERT_EQUAL_MEMORY_MESSAGE") 
      full_expected = (expected.strip[0] == 42) ? expected.slice(1..-1) : "&(#{expected})"
      return "#{unity_func}(#{full_expected}, &(#{actual}), sizeof(#{c_type})#{unity_msg})"  
    else
      return "#{unity_func}(#{expected}, #{actual}#{unity_msg})" 
    end  
  end
end