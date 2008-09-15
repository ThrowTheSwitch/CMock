
class CMockGeneratorPluginIgnore

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
    return "#{@tab}#{@config.ignore_bool_type} #{function_name}_IgnoreBool;\n"
  end
  
  def mock_function_declarations(function_name, function_args, function_return_type)
    if (function_return_type == "void")
      return "void #{function_name}_Ignore(void);\n"
    else        
      return "void #{function_name}_IgnoreAndReturn(#{function_return_type} toReturn);\n"
    end 
  end
  
  def mock_implementation_prefix(function_name, function_return_type)
    lines = []
    lines << "#{@tab}if (!Mock.#{function_name}_IgnoreBool)\n"
    lines << "#{@tab}{\n"  
    lines << @utils.make_handle_return(function_name, function_return_type, "#{@tab}#{@tab}")
    lines << "#{@tab}}\n"  
  end
  
  def mock_implementation(function_name, function_args_as_array)
    []
  end
  
  def mock_interfaces(function_name, function_args, function_args_as_array, function_return_type)
    lines = []
    if (function_return_type == "void")
      lines << "void #{function_name}_Ignore(void)\n"
      lines << "{\n"
      lines << "#{@tab}Mock.#{function_name}_IgnoreBool = (unsigned char)1;\n"
      lines << "}\n\n"
    else
      lines << "void #{function_name}_IgnoreAndReturn(#{function_return_type} toReturn)\n"
      lines << "{\n"
      lines << "#{@tab}Mock.#{function_name}_IgnoreBool = (unsigned char)1;\n"
      lines << @utils.make_expand_array(function_return_type, "Mock.#{function_name}_Return_Head", "toReturn")
      lines << "#{@tab}Mock.#{function_name}_Return = Mock.#{function_name}_Return_Head;\n"
      lines << "#{@tab}Mock.#{function_name}_Return += Mock.#{function_name}_CallCount;\n"
      lines << "}\n\n"
    end
    return lines
  end
  
  def mock_verify(function_name)
    []
  end
  
  def mock_destroy(function_name, function_args_as_array, function_return_type)
    []
  end
end
