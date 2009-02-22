
class CMockGeneratorPluginExpect

  attr_reader :config, :utils, :tab, :unity_helper

  def initialize(config, utils)
    @config = config
	  @tab = @config.tab
    @ptr_handling = @config.when_ptr_star
    @utils = utils
    @unity_helper = @utils.helpers[:unity_helper]
  end
  
  def instance_structure(function)
    call_count_type = @config.expect_call_count_type
    lines = []
    lines << "#{@tab}#{call_count_type} #{function[:name]}_CallCount;\n"
    lines << "#{@tab}#{call_count_type} #{function[:name]}_CallsExpected;\n"
      
    if (function[:rettype] != "void")
      lines << "#{@tab}#{function[:rettype]} *#{function[:name]}_Return;\n"
      lines << "#{@tab}#{function[:rettype]} *#{function[:name]}_Return_Head;\n"
      lines << "#{@tab}#{function[:rettype]} *#{function[:name]}_Return_Tail;\n"
    end

    function[:args].each do |arg|
      type = arg[:type].sub(/const/, '').strip
      lines << "#{@tab}#{type} *#{function[:name]}_Expected_#{arg[:name]};\n"
      lines << "#{@tab}#{type} *#{function[:name]}_Expected_#{arg[:name]}_Head;\n"
      lines << "#{@tab}#{type} *#{function[:name]}_Expected_#{arg[:name]}_Tail;\n"
    end
    lines
  end
  
  def mock_function_declarations(function)
    if (function[:args_string] == "void")
      if (function[:rettype] == 'void')
        return "void #{function[:name]}_Expect(void);\n"
      else
        return "void #{function[:name]}_ExpectAndReturn(#{function[:rettype]} toReturn);\n"
      end
    else        
      if (function[:rettype] == 'void')
        return "void #{function[:name]}_Expect(#{function[:args_string]});\n"
      else
        return "void #{function[:name]}_ExpectAndReturn(#{function[:args_string]}, #{function[:rettype]} toReturn);\n"
      end
    end
  end
  
  def mock_implementation(function)
    lines = []
    lines << "#{@tab}Mock.#{function[:name]}_CallCount++;\n"
    lines << "#{@tab}if (Mock.#{function[:name]}_CallCount > Mock.#{function[:name]}_CallsExpected)\n"
    lines << "#{@tab}{\n"
    lines << "#{@tab}#{@tab}TEST_FAIL(\"#{function[:name]} Called More Times Than Expected\");\n"
    lines << "#{@tab}}\n"
    function[:args].each do |arg|
      arg_return_type = arg[:type].sub(/const/, '').strip
      lines << @utils.code_verify_an_arg_expectation(function, arg_return_type, arg[:name])
    end
    lines
  end
  
  def mock_interfaces(function)
    lines = []
    
    # Parameter Helper Function
    if (function[:args_string] != "void")
      lines << "void ExpectParameters_#{function[:name]}(#{function[:args_string]})\n"
      lines << "{\n"
      function[:args].each do |arg|
        type = arg[:type].sub(/const/, '').strip
        lines << @utils.code_add_an_arg_expectation(function, type, arg[:name])
      end
      lines << "}\n\n"
    end
    
    #Main Mock Interface
    if (function[:rettype] == "void")
      lines << "void #{function[:name]}_Expect(#{function[:args_string]})\n"
    else
      if (function[:args_string] == "void")
        lines << "void #{function[:name]}_ExpectAndReturn(#{function[:rettype]} toReturn)\n"
      else
        lines << "void #{function[:name]}_ExpectAndReturn(#{function[:args_string]}, #{function[:rettype]} toReturn)\n"
      end
    end
    lines << "{\n"
    lines << "#{@tab}Mock.#{function[:name]}_CallsExpected++;\n"
    
    if (function[:args_string] != "void")
      lines << "#{@tab}ExpectParameters_#{function[:name]}(#{@utils.create_call_list(function)});\n"
    end
    
    if (function[:rettype] != "void")
      lines << @utils.code_insert_item_into_expect_array(function[:rettype], "Mock.#{function[:name]}_Return_Head", "toReturn")
      lines << "#{@tab}Mock.#{function[:name]}_Return = Mock.#{function[:name]}_Return_Head;\n"
      lines << "#{@tab}Mock.#{function[:name]}_Return += Mock.#{function[:name]}_CallCount;\n"
    end
    lines << "}\n\n"
  end
  
  def mock_verify(function)
    return "#{@tab}TEST_ASSERT_EQUAL_MESSAGE(Mock.#{function[:name]}_CallsExpected, Mock.#{function[:name]}_CallCount, \"Function '#{function[:name]}' called unexpected number of times.\");\n"
  end
  
  def mock_destroy(function)
    lines = []
    if (function[:rettype] != "void")
      lines << "#{@tab}if (Mock.#{function[:name]}_Return_Head)\n"
      lines << "#{@tab}{\n"
      lines << "#{@tab}#{@tab}free(Mock.#{function[:name]}_Return_Head);\n"
      lines << "#{@tab}#{@tab}Mock.#{function[:name]}_Return_Head=NULL;\n"
      lines << "#{@tab}#{@tab}Mock.#{function[:name]}_Return_Tail=NULL;\n"
      lines << "#{@tab}}\n"
    end
    function[:args].each do |arg|
      lines << "#{@tab}if (Mock.#{function[:name]}_Expected_#{arg[:name]}_Head)\n"
      lines << "#{@tab}{\n"
      lines << "#{@tab}#{@tab}free(Mock.#{function[:name]}_Expected_#{arg[:name]}_Head);\n"
      lines << "#{@tab}#{@tab}Mock.#{function[:name]}_Expected_#{arg[:name]}_Head=NULL;\n"
      lines << "#{@tab}#{@tab}Mock.#{function[:name]}_Expected_#{arg[:name]}_Tail=NULL;\n"
      lines << "#{@tab}}\n"
    end
    lines
  end
end
