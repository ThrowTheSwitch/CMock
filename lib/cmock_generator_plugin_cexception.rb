
class CMockGeneratorPluginCException

  attr_reader :config, :utils, :tab

  def initialize(config, utils)
    @config = config
	  @tab = @config.tab
    @utils = utils
  end
  
  def include_files
    include = @config.cexception_include
    include = "Exception.h" if (include.nil?)
    return "#include \"#{include}\"\n"
  end
  
  def instance_structure(function_name, function_args_as_array, function_return_type)
    lines = []
    call_count_type = @config.call_count_type
    throw_type = @config.throw_type
    lines << "#{@tab}#{call_count_type} *#{function_name}_ThrowOnCallCount;\n"
    lines << "#{@tab}#{call_count_type} *#{function_name}_ThrowOnCallCount_Head;\n"
    lines << "#{@tab}#{call_count_type} *#{function_name}_ThrowOnCallCount_HeadTail;\n"
    lines << "#{@tab}#{throw_type} *#{function_name}_ThrowValue;\n"
    lines << "#{@tab}#{throw_type} *#{function_name}_ThrowValue_Head;\n"
    lines << "#{@tab}#{throw_type} *#{function_name}_ThrowValue_HeadTail;\n"
  end
  
  def mock_function_declarations(function_name, function_args, function_return_type)
    if (function_args == "void")
	    return "void #{function_name}_ExpectAndThrow(#{@config.throw_type} toThrow);\n"
    else        
	    return "void #{function_name}_ExpectAndThrow(#{function_args}, #{@config.throw_type} toThrow);\n"
    end
  end
  
  def mock_implementation_prefix(function_name, function_return_type)
    []
  end
  
  def mock_implementation(function_name, function_args_as_array)
    lines = ["\n"]
    lines << "#{@tab}if((Mock.#{function_name}_ThrowOnCallCount != Mock.#{function_name}_ThrowOnCallCount_HeadTail) &&\n"
    lines << "#{@tab}#{@tab}(Mock.#{function_name}_ThrowValue != Mock.#{function_name}_ThrowValue_HeadTail))\n"
    lines << "#{@tab}{\n"
    lines << "#{@tab}#{@tab}if (*Mock.#{function_name}_ThrowOnCallCount && \n"
    lines << "#{@tab}#{@tab}#{@tab}(Mock.#{function_name}_CallCount == *Mock.#{function_name}_ThrowOnCallCount))\n"
    lines << "#{@tab}#{@tab}{\n"
    lines << "#{@tab}#{@tab}#{@tab}#{@config.throw_type} toThrow = *Mock.#{function_name}_ThrowValue;\n"
    lines << "#{@tab}#{@tab}#{@tab}Mock.#{function_name}_ThrowOnCallCount++;\n"
    lines << "#{@tab}#{@tab}#{@tab}Mock.#{function_name}_ThrowValue++;\n"
    lines << "#{@tab}#{@tab}#{@tab}Throw(toThrow);\n"
    lines << "#{@tab}#{@tab}}\n"
    lines << "#{@tab}}\n"
  end
  
  def mock_interfaces(function_name, function_args, function_args_as_array, function_return_type)
    arg_insert = (function_args == "void") ? "" : "#{function_args}, "
    call_count_type = @config.call_count_type
    throw_type = @config.throw_type
    lines = []
    lines << "void #{function_name}_ExpectAndThrow(#{arg_insert}#{throw_type} toThrow)\n"
    lines << "{\n"
    lines << "#{@tab}Mock.#{function_name}_CallsExpected++;\n"
    lines << @utils.make_expand_array(call_count_type, "Mock.#{function_name}_ThrowOnCallCount_Head", "Mock.#{function_name}_CallsExpected")
    lines << "#{@tab}Mock.#{function_name}_ThrowOnCallCount = Mock.#{function_name}_ThrowOnCallCount_Head;\n"
    lines << "#{@tab}Mock.#{function_name}_ThrowOnCallCount += Mock.#{function_name}_CallCount;\n"
    lines << @utils.make_expand_array(throw_type, "Mock.#{function_name}_ThrowValue_Head", "toThrow")
    lines << "#{@tab}Mock.#{function_name}_ThrowValue = Mock.#{function_name}_ThrowValue_Head;\n"      
    lines << "#{@tab}Mock.#{function_name}_ThrowValue += Mock.#{function_name}_CallCount;\n"
    lines << "#{@tab}ExpectParameters_#{function_name}(#{@utils.create_call_list(function_args_as_array)});\n" if (function_args != "void")
    lines << "}\n\n"
  end
  
  def mock_verify(function_name)
    []
  end
  
  def mock_destroy(function_name, function_args_as_array, function_return_type)
    lines = []
    lines << "#{@tab}if(Mock.#{function_name}_ThrowOnCallCount_Head)\n"
    lines << "#{@tab}{\n"
    lines << "#{@tab}#{@tab}free(Mock.#{function_name}_ThrowOnCallCount_Head);\n"
    lines << "#{@tab}#{@tab}Mock.#{function_name}_ThrowOnCallCount_Head=NULL;\n"
    lines << "#{@tab}#{@tab}Mock.#{function_name}_ThrowOnCallCount_HeadTail=NULL;\n"
    lines << "#{@tab}}\n"
	
    lines << "#{@tab}if(Mock.#{function_name}_ThrowValue_Head)\n"
    lines << "#{@tab}{\n"
    lines << "#{@tab}#{@tab}free(Mock.#{function_name}_ThrowValue_Head);\n"
    lines << "#{@tab}#{@tab}Mock.#{function_name}_ThrowValue_Head=NULL;\n"
    lines << "#{@tab}#{@tab}Mock.#{function_name}_ThrowValue_HeadTail=NULL;\n"
    lines << "#{@tab}}\n"
  end
end
