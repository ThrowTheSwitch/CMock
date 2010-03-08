
class CMockGeneratorUtils

  attr_accessor :config, :helpers, :ordered, :ptr_handling, :arrays, :cexception

  def initialize(config, helpers={})
    @config = config
    @ptr_handling = @config.when_ptr
    @ordered = @config.enforce_strict_ordering
    @arrays = @config.plugins.include? :array
    @cexception = @config.plugins.include? :cexception
    @treat_as = @config.treat_as
	  @helpers = helpers
  end
  
  def code_add_base_expectation(func_name, global_ordering_supported=true)
    lines =  "  CMOCK_#{func_name}_CALL_INSTANCE* cmock_call_instance = (CMOCK_#{func_name}_CALL_INSTANCE*)CMock_Guts_MemNew(sizeof(CMOCK_#{func_name}_CALL_INSTANCE));\n"
    lines << "  TEST_ASSERT_NOT_NULL_MESSAGE(cmock_call_instance, \"CMock has run out of memory. Please allocate more.\");\n"
    lines << "  Mock.#{func_name}_CallInstance = (CMOCK_#{func_name}_CALL_INSTANCE*)CMock_Guts_MemChain((void*)Mock.#{func_name}_CallInstance, (void*)cmock_call_instance);\n"
    lines << "  cmock_call_instance->CallOrder = ++GlobalExpectCount;\n" if (@ordered and global_ordering_supported)
    lines << "  cmock_call_instance->ExceptionToThrow = CEXCEPTION_NONE;\n" if (@cexception)
    lines
  end
  
  def code_add_an_arg_expectation(arg, depth=1) 
    lines =  code_assign_argument_quickly("cmock_call_instance->Expected_#{arg[:name]}", arg)
    lines << "  cmock_call_instance->Expected_#{arg[:name]}_Depth = #{arg[:name]}_Depth;\n" if (@arrays and (depth.class == String))
    lines
  end
  
  def code_assign_argument_quickly(dest, arg) 
    if (arg[:ptr?] or @treat_as.include?(arg[:type]))
      "  #{dest} = #{arg[:const?] ? "(#{arg[:type]})" : ''}#{arg[:name]};\n"
    else
      "  memcpy(&#{dest}, &#{arg[:name]}, sizeof(#{arg[:type]}));\n"
    end
  end
  
  def code_add_argument_loader(function)
    if (function[:args_string] != "void")
      if (@arrays)
        args_string = function[:args].map{|m| m[:ptr?] ? "#{m[:type]} #{m[:name]}, int #{m[:name]}_Depth" : "#{m[:type]} #{m[:name]}"}.join(', ')
        "void CMockExpectParameters_#{function[:name]}(CMOCK_#{function[:name]}_CALL_INSTANCE* cmock_call_instance, #{args_string})\n{\n" + 
        function[:args].inject("") { |all, arg| all + code_add_an_arg_expectation(arg, (arg[:ptr?] ? "#{arg[:name]}_Depth" : 1) ) } +
        "}\n\n"
      else
        "void CMockExpectParameters_#{function[:name]}(CMOCK_#{function[:name]}_CALL_INSTANCE* cmock_call_instance, #{function[:args_string]})\n{\n" + 
        function[:args].inject("") { |all, arg| all + code_add_an_arg_expectation(arg) } +
        "}\n\n"
      end
    else
      ""
    end
  end
  
  def code_call_argument_loader(function)
    if (function[:args_string] != "void")
      args = function[:args].map do |m|
        arg = m[:const?] ? "(#{m[:type]})#{m[:name]}" : m[:name]
        (@arrays and m[:ptr?]) ? "#{arg}, 1" : arg
      end
      "  CMockExpectParameters_#{function[:name]}(cmock_call_instance, #{args.join(', ')});\n" 
    else
      ""
    end
  end
  
  def code_verify_an_arg_expectation(function, arg)
    c_type = arg[:type]
    arg_name = arg[:name]
    expected = "cmock_call_instance->Expected_#{arg_name}"
    msg = "\"Function '#{function[:name]}' called with unexpected value for argument '#{arg_name}'.\""
    depth_name = (arg[:ptr?]) ? "cmock_call_instance->Expected_#{arg_name}_Depth" : 1
    if ((arg[:ptr?]) and (@ptr_handling == :compare_ptr))
      unity_func = "TEST_ASSERT_EQUAL_HEX32_MESSAGE"
    else
      unity_func = (@helpers.nil? or @helpers[:unity_helper].nil?) ? "TEST_ASSERT_EQUAL_MESSAGE" : @helpers[:unity_helper].get_helper(c_type)
    end
    unity_msg  = (unity_func =~ /_MESSAGE/) ? ", #{msg}" : ''
    case(unity_func)
      when "TEST_ASSERT_EQUAL_MEMORY_MESSAGE"
        full_expected = (expected =~ /^\*/) ? expected.slice(1..-1) : "(&#{expected})"
        return "  TEST_ASSERT_EQUAL_MEMORY_MESSAGE((void*)#{full_expected}, (void*)(&#{arg_name}), sizeof(#{c_type})#{unity_msg});\n"
      when "TEST_ASSERT_EQUAL_MEMORY_MESSAGE_ARRAY"
        if (@arrays)
          [ "  if (#{expected} == NULL)",
            "    { TEST_ASSERT_NULL(#{arg_name}); }",
            (((@ptr_handling == :smart) and (depth_name != 1)) ? "  else if (#{depth_name} == 0)\n    { TEST_ASSERT_EQUAL_HEX32(#{expected}, #{arg_name}); }" : nil),
            "  else",
            "    { TEST_ASSERT_EQUAL_MEMORY_ARRAY_MESSAGE((void*)(#{expected}), (void*)#{arg_name}, sizeof(#{c_type.sub('*','')}), #{depth_name}#{unity_msg}); }\n"].compact.join("\n")
        else
          [ "  if (#{expected} == NULL)",
            "    { TEST_ASSERT_NULL(#{arg_name}); }",
            "  else",
            "    { TEST_ASSERT_EQUAL_MEMORY_MESSAGE((void*)(#{expected}), (void*)#{arg_name}, sizeof(#{c_type.sub('*','')})#{unity_msg}); }\n"].join("\n")

        end
      when /_ARRAY/
        if (@arrays)
          [ "  if (#{expected} == NULL)",
            "    { TEST_ASSERT_NULL(#{arg_name}); }",
            (((@ptr_handling == :smart) and (depth_name != 1)) ? "  else if (#{depth_name} == 0)\n    { TEST_ASSERT_EQUAL_HEX32(#{expected}, #{arg_name}); }" : nil),
            "  else",
            "    { #{unity_func}(#{expected}, #{arg_name}, #{depth_name}); }\n"].compact.join("\n")
        else
          [ "  if (#{expected} == NULL)",
            "    { TEST_ASSERT_NULL(#{arg_name}); }",
            "  else",
            "    { #{unity_func}(#{expected}, #{arg_name}, 1); }\n"].join("\n")
        end
      else
        return "  #{unity_func}(#{expected}, #{arg_name}#{unity_msg});\n" 
    end  
  end
  
end