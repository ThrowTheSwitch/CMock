
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
    return ["#include \"#{include}\"\n"]
  end
  
  def instance_structure(function)
    call_count_type = @config.expect_call_count_type
    throw_type = @config.cexception_throw_type
    [ "#{@tab}#{call_count_type} *#{function[:name]}_ThrowOnCallCount;\n",
      "#{@tab}#{call_count_type} *#{function[:name]}_ThrowOnCallCount_Head;\n",
      "#{@tab}#{call_count_type} *#{function[:name]}_ThrowOnCallCount_Tail;\n",
      "#{@tab}#{throw_type} *#{function[:name]}_ThrowValue;\n",
      "#{@tab}#{throw_type} *#{function[:name]}_ThrowValue_Head;\n",
      "#{@tab}#{throw_type} *#{function[:name]}_ThrowValue_Tail;\n" ]
  end
  
  def mock_function_declarations(function)
    if (function[:args_string] == "void")
	    return ["void #{function[:name]}_ExpectAndThrow(#{@config.cexception_throw_type} toThrow);\n"]
    else        
	    return ["void #{function[:name]}_ExpectAndThrow(#{function[:args_string]}, #{@config.cexception_throw_type} toThrow);\n"]
    end
  end
  
  def mock_implementation(function)
    [ "\n",
      "#{@tab}if((Mock.#{function[:name]}_ThrowOnCallCount != Mock.#{function[:name]}_ThrowOnCallCount_Tail) &&\n",
      "#{@tab}#{@tab}(Mock.#{function[:name]}_ThrowValue != Mock.#{function[:name]}_ThrowValue_Tail))\n",
      "#{@tab}{\n",
      "#{@tab}#{@tab}if (*Mock.#{function[:name]}_ThrowOnCallCount && \n",
      "#{@tab}#{@tab}#{@tab}(Mock.#{function[:name]}_CallCount == *Mock.#{function[:name]}_ThrowOnCallCount))\n",
      "#{@tab}#{@tab}{\n",
      "#{@tab}#{@tab}#{@tab}#{@config.cexception_throw_type} toThrow = *Mock.#{function[:name]}_ThrowValue;\n",
      "#{@tab}#{@tab}#{@tab}Mock.#{function[:name]}_ThrowOnCallCount++;\n",
      "#{@tab}#{@tab}#{@tab}Mock.#{function[:name]}_ThrowValue++;\n",
      "#{@tab}#{@tab}#{@tab}Throw(toThrow);\n",
      "#{@tab}#{@tab}}\n",
      "#{@tab}}\n" ]
  end
  
  def mock_interfaces(function)
    arg_insert = (function[:args_string] == "void") ? "" : "#{function[:args_string]}, "
    call_count_type = @config.expect_call_count_type
    throw_type = @config.cexception_throw_type
    [ "void #{function[:name]}_ExpectAndThrow(#{arg_insert}#{throw_type} toThrow)\n",
      "{\n",
      @utils.code_add_base_expectation(function[:name]),
      @utils.code_insert_item_into_expect_array(call_count_type, "Mock.#{function[:name]}_ThrowOnCallCount_Head", "Mock.#{function[:name]}_CallsExpected"),
      "#{@tab}Mock.#{function[:name]}_ThrowOnCallCount = Mock.#{function[:name]}_ThrowOnCallCount_Head;\n",
      "#{@tab}Mock.#{function[:name]}_ThrowOnCallCount += Mock.#{function[:name]}_CallCount;\n",
      @utils.code_insert_item_into_expect_array(throw_type, "Mock.#{function[:name]}_ThrowValue_Head", "toThrow"),
      "#{@tab}Mock.#{function[:name]}_ThrowValue = Mock.#{function[:name]}_ThrowValue_Head;\n", 
      "#{@tab}Mock.#{function[:name]}_ThrowValue += Mock.#{function[:name]}_CallCount;\n",
      (function[:args_string] != "void") ? "#{@tab}ExpectParameters_#{function[:name]}(#{@utils.create_call_list(function)});\n" : nil,
      "}\n\n" ].compact
  end
  
  def mock_destroy(function)
    [ "#{@tab}if(Mock.#{function[:name]}_ThrowOnCallCount_Head)\n",
      "#{@tab}{\n",
      "#{@tab}#{@tab}free(Mock.#{function[:name]}_ThrowOnCallCount_Head);\n",
      "#{@tab}#{@tab}Mock.#{function[:name]}_ThrowOnCallCount_Head=NULL;\n",
      "#{@tab}#{@tab}Mock.#{function[:name]}_ThrowOnCallCount_Tail=NULL;\n",
      "#{@tab}}\n",
    	"#{@tab}if(Mock.#{function[:name]}_ThrowValue_Head)\n",
      "#{@tab}{\n",
      "#{@tab}#{@tab}free(Mock.#{function[:name]}_ThrowValue_Head);\n",
      "#{@tab}#{@tab}Mock.#{function[:name]}_ThrowValue_Head=NULL;\n",
      "#{@tab}#{@tab}Mock.#{function[:name]}_ThrowValue_Tail=NULL;\n",
      "#{@tab}}\n" ]
  end
end
