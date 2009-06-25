
class CMockGeneratorPluginCException

  attr_reader :config, :utils

  def initialize(config, utils)
    @config = config
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
    [ "  #{call_count_type} *#{function[:name]}_ThrowOnCallCount;\n",
      "  #{call_count_type} *#{function[:name]}_ThrowOnCallCount_Head;\n",
      "  #{call_count_type} *#{function[:name]}_ThrowOnCallCount_Tail;\n",
      "  #{throw_type} *#{function[:name]}_ThrowValue;\n",
      "  #{throw_type} *#{function[:name]}_ThrowValue_Head;\n",
      "  #{throw_type} *#{function[:name]}_ThrowValue_Tail;\n" ]
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
      "  if((Mock.#{function[:name]}_ThrowOnCallCount != Mock.#{function[:name]}_ThrowOnCallCount_Tail) &&\n",
      "    (Mock.#{function[:name]}_ThrowValue != Mock.#{function[:name]}_ThrowValue_Tail))\n",
      "  {\n",
      "    if (*Mock.#{function[:name]}_ThrowOnCallCount && \n",
      "      (Mock.#{function[:name]}_CallCount == *Mock.#{function[:name]}_ThrowOnCallCount))\n",
      "    {\n",
      "      #{@config.cexception_throw_type} toThrow = *Mock.#{function[:name]}_ThrowValue;\n",
      "      Mock.#{function[:name]}_ThrowOnCallCount++;\n",
      "      Mock.#{function[:name]}_ThrowValue++;\n",
      "      Throw(toThrow);\n",
      "    }\n",
      "  }\n" ]
  end
  
  def mock_interfaces(function)
    arg_insert = (function[:args_string] == "void") ? "" : "#{function[:args_string]}, "
    call_count_type = @config.expect_call_count_type
    throw_type = @config.cexception_throw_type
    [ "void #{function[:name]}_ExpectAndThrow(#{arg_insert}#{throw_type} toThrow)\n",
      "{\n",
      @utils.code_add_base_expectation(function[:name]),
      @utils.code_insert_item_into_expect_array(call_count_type, "Mock.#{function[:name]}_ThrowOnCallCount_Head", "Mock.#{function[:name]}_CallsExpected"),
      @utils.code_insert_item_into_expect_array(throw_type, "Mock.#{function[:name]}_ThrowValue_Head", "toThrow"),
      "  Mock.#{function[:name]}_ThrowValue = Mock.#{function[:name]}_ThrowValue_Head;\n", 
      "  Mock.#{function[:name]}_ThrowOnCallCount = Mock.#{function[:name]}_ThrowOnCallCount_Head;\n",
      "  while ((*Mock.#{function[:name]}_ThrowOnCallCount <= Mock.#{function[:name]}_CallCount) && (Mock.#{function[:name]}_ThrowOnCallCount < Mock.#{function[:name]}_ThrowOnCallCount_Tail))\n",
      "  {\n",
      "    Mock.#{function[:name]}_ThrowValue++;\n",
      "    Mock.#{function[:name]}_ThrowOnCallCount++;\n",
      "  }\n",
      (function[:args_string] != "void") ? "  ExpectParameters_#{function[:name]}(#{@utils.create_call_list(function)});\n" : nil,
      "}\n\n" ].compact
  end
  
  def mock_destroy(function)
    [ "  if(Mock.#{function[:name]}_ThrowOnCallCount_Head)\n",
      "  {\n",
      "    free(Mock.#{function[:name]}_ThrowOnCallCount_Head);\n",
      "  }\n",
      "  Mock.#{function[:name]}_ThrowOnCallCount=NULL;\n",
      "  Mock.#{function[:name]}_ThrowOnCallCount_Head=NULL;\n",
      "  Mock.#{function[:name]}_ThrowOnCallCount_Tail=NULL;\n",
    	"  if(Mock.#{function[:name]}_ThrowValue_Head)\n",
      "  {\n",
      "    free(Mock.#{function[:name]}_ThrowValue_Head);\n",
      "  }\n",
      "  Mock.#{function[:name]}_ThrowValue=NULL;\n",
      "  Mock.#{function[:name]}_ThrowValue_Head=NULL;\n",
      "  Mock.#{function[:name]}_ThrowValue_Tail=NULL;\n"
    ]
  end
end
