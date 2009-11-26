
class CMockGeneratorPluginArray
  
  attr_accessor :config, :utils, :unity_helper, :ordered
  
  def initialize(config, utils)
    @config       = config
    @ptr_handling = @config.when_ptr_star
    @ordered      = @config.enforce_strict_ordering
    @utils        = utils
    @unity_helper = @utils.helpers[:unity_helper]
  end
  
  def instance_structure(function)
    lines = ""
    function[:args].each do |arg|
      lines << INSTANCE_STRUCTURE_ITEM_SNIPPET % "#{function[:name]}_Expected_#{arg[:name]}" if (arg[:ptr?])
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
      if (function[:return_type] == 'void')
        return "void #{function[:name]}_ExpectWithArray(#{function[:args_string]});\n"
      else
        return "void #{function[:name]}_ExpectWithArrayAndReturn(#{function[:args_string]}, #{function[:return_string]});\n"
      end
    end
  end
  
  def mock_implementation(function)
    nil
  end
  
  def mock_interfaces(function)
    return nil unless function[:args_string].include? '*'
    nil
  end
  
  def mock_verify(function)
    nil
  end
  
  def mock_destroy(function)
    nil
  end
  
  private #####################
  
  INSTANCE_STRUCTURE_ITEM_SNIPPET = %q[
  int* %1$s_Depth;
  int* %1$s_Depth_Head;
  int* %1$s_Depth_Tail;
]

end
