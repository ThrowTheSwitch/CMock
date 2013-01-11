# ==========================================
#   CMock Project - Automatic Mock Generation for C
#   Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
#   [Released under MIT License. Please refer to license.txt for details]
# ========================================== 

class CMockGeneratorPluginOriginal

  attr_reader :priority
  attr_accessor :config, :utils, :unity_helper, :ordered

  def initialize(config, utils)
    @config       = config
    @ptr_handling = @config.when_ptr
    @ordered      = @config.enforce_strict_ordering
    @utils        = utils
    @unity_helper = @utils.helpers[:unity_helper]
    @priority     = 5
    @api          = "MOCKGOTHIC_API"
  end

  def mock_function_declarations(function)
  
    if (function[:args].empty?)
      if (function[:return][:void?])
        return "#{@api} #{function[:return][:type]} #{function[:name]}();\n"
      else
        return "#{@api} #{function[:return][:type]} #{function[:name]}();\n"
      end
    else       

    # Create argument string, including variable arguments if there are any
    args_string = function[:args_string]
    args_string += (", " + function[:var_arg]) unless (function[:var_arg].nil?) 
    
      if (function[:return][:void?])
        return "#{@api} #{function[:return][:type]} #{function[:name]}(#{args_string});\n"
      else
        return "#{@api} #{function[:return][:type]} #{function[:name]}(#{args_string});\n"
      end
    end
  end

end
