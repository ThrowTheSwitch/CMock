
class CMockGeneratorPluginCException

  attr_reader :config, :utils, :tab

  def initialize(config, utils)
    @config = config
	  @tab = @config.tab
    @utils = utils
    
    ["cexception_include", "cexception_throw_type"].each do |req|
      raise "'#{req}' needs to be defined in config" unless @config.respond_to?(req)
    end
  end
  
  def include_files
    include = @config.cexception_include
    include = "Exception.h" if (include.nil?)
    return "#include \"#{include}\"\n"
  end
  
  def instance_structure(function)
    lines = []
    call_count_type = @config.cexception_call_count_type
    throw_type = @config.cexception_throw_type
    lines << "#{@tab}#{call_count_type} *#{function[:name]}_ThrowOnCallCount;\n"
    lines << "#{@tab}#{call_count_type} *#{function[:name]}_ThrowOnCallCount_Head;\n"
    lines << "#{@tab}#{call_count_type} *#{function[:name]}_ThrowOnCallCount_Tail;\n"
    lines << "#{@tab}#{throw_type} *#{function[:name]}_ThrowValue;\n"
    lines << "#{@tab}#{throw_type} *#{function[:name]}_ThrowValue_Head;\n"
    lines << "#{@tab}#{throw_type} *#{function[:name]}_ThrowValue_Tail;\n"
  end
  
  def mock_function_declarations(function)
    if (function[:args_string] == "void")
	    return "void #{function[:name]}_ExpectAndThrow(#{@config.cexception_throw_type} toThrow);\n"
    else        
	    return "void #{function[:name]}_ExpectAndThrow(#{function[:args_string]}, #{@config.cexception_throw_type} toThrow);\n"
    end
  end
  
  def mock_implementation(function)
    lines = ["\n"]
    lines << "#{@tab}if((Mock.#{function[:name]}_ThrowOnCallCount != Mock.#{function[:name]}_ThrowOnCallCount_Tail) &&\n"
    lines << "#{@tab}#{@tab}(Mock.#{function[:name]}_ThrowValue != Mock.#{function[:name]}_ThrowValue_Tail))\n"
    lines << "#{@tab}{\n"
    lines << "#{@tab}#{@tab}if (*Mock.#{function[:name]}_ThrowOnCallCount && \n"
    lines << "#{@tab}#{@tab}#{@tab}(Mock.#{function[:name]}_CallCount == *Mock.#{function[:name]}_ThrowOnCallCount))\n"
    lines << "#{@tab}#{@tab}{\n"
    lines << "#{@tab}#{@tab}#{@tab}#{@config.cexception_throw_type} toThrow = *Mock.#{function[:name]}_ThrowValue;\n"
    lines << "#{@tab}#{@tab}#{@tab}Mock.#{function[:name]}_ThrowOnCallCount++;\n"
    lines << "#{@tab}#{@tab}#{@tab}Mock.#{function[:name]}_ThrowValue++;\n"
    lines << "#{@tab}#{@tab}#{@tab}Throw(toThrow);\n"
    lines << "#{@tab}#{@tab}}\n"
    lines << "#{@tab}}\n"
  end
  
  def mock_interfaces(function)
    arg_insert = (function[:args_string] == "void") ? "" : "#{function[:args_string]}, "
    call_count_type = @config.cexception_call_count_type
    throw_type = @config.cexception_throw_type
    lines = []
    lines << "void #{function[:name]}_ExpectAndThrow(#{arg_insert}#{throw_type} toThrow)\n"
    lines << "{\n"
    lines << "#{@tab}Mock.#{function[:name]}_CallsExpected++;\n"
    lines << @utils.code_insert_item_into_expect_array(call_count_type, "Mock.#{function[:name]}_ThrowOnCallCount_Head", "Mock.#{function[:name]}_CallsExpected")
    lines << "#{@tab}Mock.#{function[:name]}_ThrowOnCallCount = Mock.#{function[:name]}_ThrowOnCallCount_Head;\n"
    lines << "#{@tab}Mock.#{function[:name]}_ThrowOnCallCount += Mock.#{function[:name]}_CallCount;\n"
    lines << @utils.code_insert_item_into_expect_array(throw_type, "Mock.#{function[:name]}_ThrowValue_Head", "toThrow")
    lines << "#{@tab}Mock.#{function[:name]}_ThrowValue = Mock.#{function[:name]}_ThrowValue_Head;\n"      
    lines << "#{@tab}Mock.#{function[:name]}_ThrowValue += Mock.#{function[:name]}_CallCount;\n"
    lines << "#{@tab}ExpectParameters_#{function[:name]}(#{@utils.create_call_list(function)});\n" if (function[:args_string] != "void")
    lines << "}\n\n"
  end
  
  def mock_destroy(function)
    lines = []
    lines << "#{@tab}if(Mock.#{function[:name]}_ThrowOnCallCount_Head)\n"
    lines << "#{@tab}{\n"
    lines << "#{@tab}#{@tab}free(Mock.#{function[:name]}_ThrowOnCallCount_Head);\n"
    lines << "#{@tab}#{@tab}Mock.#{function[:name]}_ThrowOnCallCount_Head=NULL;\n"
    lines << "#{@tab}#{@tab}Mock.#{function[:name]}_ThrowOnCallCount_Tail=NULL;\n"
    lines << "#{@tab}}\n"
	
    lines << "#{@tab}if(Mock.#{function[:name]}_ThrowValue_Head)\n"
    lines << "#{@tab}{\n"
    lines << "#{@tab}#{@tab}free(Mock.#{function[:name]}_ThrowValue_Head);\n"
    lines << "#{@tab}#{@tab}Mock.#{function[:name]}_ThrowValue_Head=NULL;\n"
    lines << "#{@tab}#{@tab}Mock.#{function[:name]}_ThrowValue_Tail=NULL;\n"
    lines << "#{@tab}}\n"
  end
end
