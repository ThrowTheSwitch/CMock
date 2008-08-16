
class CMockGeneratorPluginExpect

  attr_reader :config, :utils, :tab

  def initialize(config, utils)
    @config = config
	  @tab = @config.tab
    @utils = utils
  end
  
  def include_files
    []
  end
  
  def instance_structure(function_name, function_args_as_array, function_return_type)
    call_count_type = @config.call_count_type
    lines = []
    lines << "#{@tab}#{call_count_type} #{function_name}_CallCount;\n"
    lines << "#{@tab}#{call_count_type} #{function_name}_CallsExpected;\n"
      
    if (function_return_type != "void")
      lines << "#{@tab}#{function_return_type} *#{function_name}_Return;\n"
      lines << "#{@tab}#{function_return_type} *#{function_name}_Return_Head;\n"
      lines << "#{@tab}#{function_return_type} *#{function_name}_Return_HeadTail;\n"
    end

    function_args_as_array.each do |arg|
      type = arg[:type].sub(/const/, '').strip
      lines << "#{@tab}#{type} *#{function_name}_Expected_#{arg[:name]};\n"
      lines << "#{@tab}#{type} *#{function_name}_Expected_#{arg[:name]}_Head;\n"
      lines << "#{@tab}#{type} *#{function_name}_Expected_#{arg[:name]}_HeadTail;\n"
    end
    lines
  end
  
  def mock_function_declarations(function_name, function_args, function_return_type)
    if (function_args == "void")
      if (function_return_type == 'void')
        return "void #{function_name}_Expect(void);\n"
      else
        return "void #{function_name}_ExpectAndReturn(#{function_return_type} toReturn);\n"
      end
    else        
      if (function_return_type == 'void')
        return "void #{function_name}_Expect(#{function_args});\n"
      else
        return "void #{function_name}_ExpectAndReturn(#{function_args}, #{function_return_type} toReturn);\n"
      end
    end
  end
  
  def mock_implementation_prefix(function_name, function_return_type)
    []
  end
  
  def mock_implementation(function_name, function_args_as_array)
    lines = []
    lines << "#{@tab}Mock.#{function_name}_CallCount++;\n"
    lines << "#{@tab}if (Mock.#{function_name}_CallCount > Mock.#{function_name}_CallsExpected)\n"
    lines << "#{@tab}{\n"
    lines << "#{@tab}#{@tab}TEST_THROW(\"#{function_name} Called More Times Than Expected\");\n"
    lines << "#{@tab}}\n"
    function_args_as_array.each do |arg|
      function_return_type = arg[:type].sub(/const/, '').strip
      lines << @utils.make_handle_expected(function_name, function_return_type, arg[:name])
    end
    lines
  end
  
  def mock_interfaces(function_name, function_args, function_args_as_array, function_return_type)
    lines = []
    
    # Parameter Helper Function
    if (function_args != "void")
      lines << "void ExpectParameters_#{function_name}(#{function_args})\n"
      lines << "{\n"
      function_args_as_array.each do |arg|
        type = arg[:type].sub(/const/, '').strip
        lines << @utils.make_add_new_expected(function_name, type, arg[:name])
      end
      lines << "}\n\n"
    end
    
    #Main Mock Interface
    if (function_return_type == "void")
      lines << "void #{function_name}_Expect(#{function_args})\n"
    else
      if (function_args == "void")
        lines << "void #{function_name}_ExpectAndReturn(#{function_return_type} toReturn)\n"
      else
        lines << "void #{function_name}_ExpectAndReturn(#{function_args}, #{function_return_type} toReturn)\n"
      end
    end
    lines << "{\n"
    lines << "#{@tab}Mock.#{function_name}_CallsExpected++;\n"
    
    if (function_args != "void")
      lines << "#{@tab}ExpectParameters_#{function_name}(#{@utils.create_call_list(function_args_as_array)});\n"
    end
    
    if (function_return_type != "void")
      lines << @utils.make_expand_array(function_return_type, "Mock.#{function_name}_Return_Head", "toReturn")
      lines << "#{@tab}Mock.#{function_name}_Return = Mock.#{function_name}_Return_Head;\n"
      lines << "#{@tab}Mock.#{function_name}_Return += Mock.#{function_name}_CallCount;\n"
    end
    lines << "}\n\n"
  end
  
  def mock_verify(function_name)
    return "#{@tab}TEST_ASSERT_EQUAL_MESSAGE(Mock.#{function_name}_CallsExpected, Mock.#{function_name}_CallCount, \"Function '#{function_name}' called unexpected number of times.\");\n"
  end
  
  def mock_destroy(function_name, function_args_as_array, function_return_type)
    lines = []
    if (function_return_type != "void")
      lines << "#{@tab}if (Mock.#{function_name}_Return_Head)\n"
      lines << "#{@tab}{\n"
      lines << "#{@tab}#{@tab}free(Mock.#{function_name}_Return_Head);\n"
      lines << "#{@tab}#{@tab}Mock.#{function_name}_Return_Head=NULL;\n"
      lines << "#{@tab}#{@tab}Mock.#{function_name}_Return_HeadTail=NULL;\n"
      lines << "#{@tab}}\n"
    end
    function_args_as_array.each do |arg|
      lines << "#{@tab}if (Mock.#{function_name}_Expected_#{arg[:name]}_Head)\n"
      lines << "#{@tab}{\n"
      lines << "#{@tab}#{@tab}free(Mock.#{function_name}_Expected_#{arg[:name]}_Head);\n"
      lines << "#{@tab}#{@tab}Mock.#{function_name}_Expected_#{arg[:name]}_Head=NULL;\n"
      lines << "#{@tab}#{@tab}Mock.#{function_name}_Expected_#{arg[:name]}_HeadTail=NULL;\n"
      lines << "#{@tab}}\n"
    end
    lines
  end
end
