
class CMockGeneratorPluginIgnore

  attr_reader :config, :utils, :tab
  
  def initialize(config, utils)
    @config = config
	  @tab = @config.tab
    @utils = utils

    ["ignore_bool_type"].each do |req|
      raise "'#{req}' needs to be defined in config" unless @config.respond_to?(req)
    end
  end
  
  def instance_structure(function)
    return "#{@tab}#{@config.ignore_bool_type} #{function[:name]}_IgnoreBool;\n"
  end
  
  def mock_function_declarations(function)
    if (function[:rettype] == "void")
      return "void #{function[:name]}_Ignore(void);\n"
    else        
      return "void #{function[:name]}_IgnoreAndReturn(#{function[:rettype]} toReturn);\n"
    end 
  end
  
  def mock_implementation_prefix(function)
    lines = []
    lines << "#{@tab}if (Mock.#{function[:name]}_IgnoreBool)\n"
    lines << "#{@tab}{\n"  
    if (function[:rettype] == "void")
      lines << "#{@tab}#{@tab}return;\n"
    else
      lines << @utils.code_handle_return_value(function, "#{@tab}#{@tab}")
    end
    lines << "#{@tab}}\n"  
  end
  
  def mock_interfaces(function)
    lines = []
    if (function[:rettype] == "void")
      lines << "void #{function[:name]}_Ignore(void)\n"
      lines << "{\n"
      lines << "#{@tab}Mock.#{function[:name]}_IgnoreBool = (unsigned char)1;\n"
      lines << "}\n\n"
    else
      lines << "void #{function[:name]}_IgnoreAndReturn(#{function[:rettype]} toReturn)\n"
      lines << "{\n"
      lines << "#{@tab}Mock.#{function[:name]}_IgnoreBool = (unsigned char)1;\n"
      lines << @utils.code_insert_item_into_expect_array(function[:rettype], "Mock.#{function[:name]}_Return_Head", "toReturn")
      lines << "#{@tab}Mock.#{function[:name]}_Return = Mock.#{function[:name]}_Return_Head;\n"
      lines << "#{@tab}Mock.#{function[:name]}_Return += Mock.#{function[:name]}_CallCount;\n"
      lines << "}\n\n"
    end
    return lines
  end
end
