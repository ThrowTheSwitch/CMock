
class CMockGeneratorPluginIgnore

  attr_reader :config, :utils
  
  def initialize(config, utils)
    @config = config
    @utils = utils

    ["ignore_bool_type"].each do |req|
      raise "'#{req}' needs to be defined in config" unless @config.respond_to?(req)
    end
  end
  
  def instance_structure(function)
    return ["  #{@config.ignore_bool_type} #{function[:name]}_IgnoreBool;\n"]
  end
  
  def mock_function_declarations(function)
    if (function[:return_type] == "void")
      return ["void #{function[:name]}_Ignore(void);\n"]
    else        
      return ["void #{function[:name]}_IgnoreAndReturn(#{function[:return_string]});\n"]
    end 
  end
  
  def mock_implementation_prefix(function)
    lines = [ "  if (Mock.#{function[:name]}_IgnoreBool)\n",
              "  {\n" 
            ] 
    if (function[:return_type] == "void")
      lines << ["    return;\n"]
    else
      lines << [ "    if (Mock.#{function[:name]}_Return != Mock.#{function[:name]}_Return_Tail)\n",
                 "    {\n",
                 "      #{function[:return_type]} toReturn = *Mock.#{function[:name]}_Return;\n",
                 "      Mock.#{function[:name]}_Return++;\n",
                 "      Mock.#{function[:name]}_CallCount++;\n",
                 "      Mock.#{function[:name]}_CallsExpected++;\n",
                 "      return toReturn;\n",
                 "    }\n",
                 "    else\n",
                 "    {\n",
                 "      return *(Mock.#{function[:name]}_Return_Tail - 1);\n",
                 "    }\n" 
               ]
    end
    lines << [ "  }\n" ]
    lines.flatten
  end
  
  def mock_interfaces(function)
    if (function[:return_type] == "void")
      [ "void #{function[:name]}_Ignore(void)\n",
        "{\n",
        "  Mock.#{function[:name]}_IgnoreBool = (unsigned char)1;\n",
        "}\n\n" ]
    else
      [ "void #{function[:name]}_IgnoreAndReturn(#{function[:return_string]})\n",
        "{\n",
        "  Mock.#{function[:name]}_IgnoreBool = (unsigned char)1;\n",
        @utils.code_insert_item_into_expect_array(function[:return_type], "Mock.#{function[:name]}_Return_Head", 'toReturn'),
        "  Mock.#{function[:name]}_Return = Mock.#{function[:name]}_Return_Head;\n",
        "  Mock.#{function[:name]}_Return += Mock.#{function[:name]}_CallCount;\n",
        "}\n\n" ]
    end
  end
end
