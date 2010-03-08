
class CMockGeneratorPluginExpect

  attr_reader :priority
  attr_accessor :config, :utils, :unity_helper, :ordered

  def initialize(config, utils)
    @config       = config
    @ptr_handling = @config.when_ptr
    @ordered      = @config.enforce_strict_ordering
    @utils        = utils
    @unity_helper = @utils.helpers[:unity_helper]
    @priority     = 5
  end
  
  def instance_typedefs(function)
    lines = ""
    lines << "  #{function[:return][:type]} ReturnVal;\n"  unless (function[:return][:void?])
    lines << "  int CallOrder;\n"                          if (@ordered)
    function[:args].each do |arg|
      lines << "  #{arg[:type]} Expected_#{arg[:name]};\n"
    end
    lines
  end
  
  def mock_function_declarations(function)
    if (function[:args].empty?)
      if (function[:return][:void?])
        return "void #{function[:name]}_Expect(void);\n"
      else
        return "void #{function[:name]}_ExpectAndReturn(#{function[:return][:str]});\n"
      end
    else        
      if (function[:return][:void?])
        return "void #{function[:name]}_Expect(#{function[:args_string]});\n"
      else
        return "void #{function[:name]}_ExpectAndReturn(#{function[:args_string]}, #{function[:return][:str]});\n"
      end
    end
  end
  
  def mock_implementation(function)
    lines = ""
    if (@ordered)
      lines << "  TEST_ASSERT_MESSAGE((cmock_call_instance->CallOrder == ++GlobalVerifyOrder), \"Out of order function calls. Function '#{function[:name]}'\");\n"
    end
    function[:args].each do |arg|
      lines << @utils.code_verify_an_arg_expectation(function, arg)
    end
    lines
  end
  
  def mock_interfaces(function)
    lines = ""
    func_name = function[:name]
    if (function[:return][:void?])
      lines << "void #{func_name}_Expect(#{function[:args_string]})\n{\n"
    else
      if (function[:args_string] == "void")
        lines << "void #{func_name}_ExpectAndReturn(#{function[:return][:str]})\n{\n"
      else
        lines << "void #{func_name}_ExpectAndReturn(#{function[:args_string]}, #{function[:return][:str]})\n{\n"
      end
    end
    lines << @utils.code_add_base_expectation(func_name)
    lines << @utils.code_call_argument_loader(function)
    lines << @utils.code_assign_argument_quickly("cmock_call_instance->ReturnVal", function[:return]) unless (function[:return][:void?])
    lines << "}\n\n"
  end
  
  def mock_verify(function)
    func_name = function[:name]
    "  TEST_ASSERT_NULL_MESSAGE(Mock.#{func_name}_CallInstance, \"Function '#{func_name}' called less times than expected.\");\n"
  end

end
