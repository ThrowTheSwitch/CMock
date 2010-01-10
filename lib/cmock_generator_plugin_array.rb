class CMockGeneratorPluginArray

  attr_reader :priority
  attr_accessor :config, :utils, :unity_helper, :ordered
  def initialize(config, utils)
    @config       = config
    @ptr_handling = @config.when_ptr
    @ordered      = @config.enforce_strict_ordering
    @utils        = utils
    @unity_helper = @utils.helpers[:unity_helper]
    @priority     = 8
  end

  def instance_structure(function)
    lines = ""
    function[:args].each do |arg|
      lines << INSTANCE_STRUCTURE_DEPTH_SNIPPET % "#{function[:name]}_Expected_#{arg[:name]}" if (arg[:ptr?])
    end
    lines
  end

  def mock_function_declarations(function)
    return nil unless function[:contains_ptr?]
    if (function[:args_string] == "void")
      if (function[:return_type] == 'void')
        return "void #{function[:name]}_ExpectWithArray(void);\n"
      else
        return "void #{function[:name]}_ExpectWithArrayAndReturn(#{function[:return_string]});\n"
      end
    else
      args_string = function[:args].map{|m| m[:ptr?] ? "#{m[:type]} #{m[:name]}, int #{m[:name]}_Depth" : "#{m[:type]} #{m[:name]}"}.join(', ')
      if (function[:return_type] == 'void')
        return "void #{function[:name]}_ExpectWithArray(#{args_string});\n"
      else
        return "void #{function[:name]}_ExpectWithArrayAndReturn(#{args_string}, #{function[:return_string]});\n"
      end
    end
  end

  def mock_interfaces(function)
    return nil unless function[:contains_ptr?]

    lines = []
    func_name = function[:name]
    args_string = function[:args].map{|m| m[:ptr?] ? "#{m[:type]} #{m[:name]}, int #{m[:name]}_Depth" : "#{m[:type]} #{m[:name]}"}.join(', ')
    call_string = function[:args].map{|m| m[:ptr?] ? "#{m[:name]}, #{m[:name]}_Depth" : m[:name]}.join(', ')

    # Parameter Helper Function
    if (function[:args_string] != "void")
      lines << "void ExpectParametersWithArray_#{func_name}(#{args_string})\n{\n"
      function[:args].each do |arg|
        lines << @utils.code_add_an_arg_expectation(function, arg, arg[:ptr?] ? "#{arg[:name]}_Depth" : "1")
      end
      lines << "}\n\n"
    end

    #Main Mock Interface
    if (function[:return_type] == "void")
      lines << "void #{func_name}_ExpectWithArray(#{args_string})\n"
    else
      lines << "void #{func_name}_ExpectWithArrayAndReturn(#{args_string}, #{function[:return_string]})\n"
    end
    lines << "{\n"
    lines << @utils.code_add_base_expectation(func_name)
    lines << "  ExpectParametersWithArray_#{func_name}(#{call_string});\n"

    if (function[:return_type] != "void")
      lines << @utils.code_insert_item_into_expect_array(function[:return_type], "Mock.#{func_name}_Return", 'cmock_to_return')
      lines << "  Mock.#{func_name}_Return = Mock.#{func_name}_Return_Head;\n"
      lines << "  Mock.#{func_name}_Return += Mock.#{func_name}_CallCount;\n"
    end
    lines << "}\n\n"
  end

  def mock_destroy(function)
    lines = []
    function[:args].each do |arg|
      lines << DESTROY_DEPTH_SNIPPET % "#{function[:name]}_Expected_#{arg[:name]}" if arg[:ptr?]
    end
    lines.flatten
  end

  private #####################

  INSTANCE_STRUCTURE_DEPTH_SNIPPET = %q[
  int* %1$s_Depth;
  int* %1$s_Depth_Head;
  int* %1$s_Depth_Tail;
]

  DESTROY_DEPTH_SNIPPET = %q[
  if (Mock.%1$s_Depth_Head)
  {
    free(Mock.%1$s_Depth_Head);
  }
  Mock.%1$s_Depth=NULL;
  Mock.%1$s_Depth_Head=NULL;
  Mock.%1$s_Depth_Tail=NULL;
]

end
