# ==========================================
#   CMock Project - Automatic Mock Generation for C
#   Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
#   [Released under MIT License. Please refer to license.txt for details]
# ========================================== 

class CMockGeneratorPluginCallback

  attr_accessor :include_count
  attr_reader :priority
  attr_reader :config, :utils
  
  def initialize(config, utils)
    @config = config
    @utils = utils
    @priority = 6
	@api = "MOCKGOTHIC_API"
    
    @include_count = @config.callback_include_count
    if (@config.callback_after_arg_check)
      alias :mock_implementation          :mock_implementation_for_callbacks
      alias :mock_implementation_precheck :nothing
    else
      alias :mock_implementation_precheck :mock_implementation_for_callbacks
      alias :mock_implementation          :nothing
    end
  end

  def instance_structure(function)
    func_name = function[:name]
    "  CMOCK_#{func_name}_CALLBACK #{func_name}_CallbackFunctionPointer;\n" +
    "  int #{func_name}_CallbackCalls;\n"
  end

  def mock_function_declarations(function)
    func_name = function[:name]
    return_type = function[:return][:const?] ? "const #{function[:return][:type]}" : function[:return][:type]
    style  = (@include_count ? 1 : 0) | (function[:args].empty? ? 0 : 2)
    styles = [ "void", "int cmock_num_calls", function[:args_string], "#{function[:args_string]}, int cmock_num_calls" ]
    "typedef #{return_type} (* CMOCK_#{func_name}_CALLBACK)(#{styles[style]});\n#{@api} void #{func_name}_StubWithCallback(CMOCK_#{func_name}_CALLBACK Callback);\n"
  end

  def mock_implementation_for_callbacks(function)
    func_name   = function[:name]
    style  = (@include_count ? 1 : 0) | (function[:args].empty? ? 0 : 2) | (function[:return][:void?] ? 0 : 4)
    "  if (Mock.#{func_name}_CallbackFunctionPointer != NULL)\n  {\n" +
    case(style)
      when 0 then "    Mock.#{func_name}_CallbackFunctionPointer();\n    return;\n  }\n"
      when 1 then "    Mock.#{func_name}_CallbackFunctionPointer(Mock.#{func_name}_CallbackCalls++);\n    return;\n  }\n"
      when 2 then "    Mock.#{func_name}_CallbackFunctionPointer(#{function[:args].map{|m| m[:name]}.join(', ')});\n    return;\n  }\n"
      when 3 then "    Mock.#{func_name}_CallbackFunctionPointer(#{function[:args].map{|m| m[:name]}.join(', ')}, Mock.#{func_name}_CallbackCalls++);\n    return;\n  }\n"
      when 4 then "    return Mock.#{func_name}_CallbackFunctionPointer();\n  }\n"
      when 5 then "    return Mock.#{func_name}_CallbackFunctionPointer(Mock.#{func_name}_CallbackCalls++);\n  }\n"
      when 6 then "    return Mock.#{func_name}_CallbackFunctionPointer(#{function[:args].map{|m| m[:name]}.join(', ')});\n  }\n"
      when 7 then "    return Mock.#{func_name}_CallbackFunctionPointer(#{function[:args].map{|m| m[:name]}.join(', ')}, Mock.#{func_name}_CallbackCalls++);\n  }\n"
    end
  end
  
  def nothing(function)
    return ""
  end

  def mock_interfaces(function)
    func_name = function[:name]
    "#{@api} void #{func_name}_StubWithCallback(CMOCK_#{func_name}_CALLBACK Callback)\n{\n" + 
    "  Mock.#{func_name}_CallbackFunctionPointer = Callback;\n}\n\n"
  end

  def mock_destroy(function)
  
	definition = preprocessor_formatting(function)
	file_name = filename_format(function)
	if (definition.include?(file_name))
	  definition = ''
    end
	"  #{definition}\n" +
    "  Mock.#{function[:name]}_CallbackFunctionPointer = NULL;\n" +
    "  Mock.#{function[:name]}_CallbackCalls = 0;\n"
  end
  
  def mock_verify(function)
    func_name = function[:name]
    "  if (Mock.#{func_name}_CallbackFunctionPointer != NULL)\n    Mock.#{func_name}_CallInstance = CMOCK_GUTS_NONE;\n"
  end
  
  def preprocessor_formatting(function)
    definition = function[:defs].to_s
	definition.gsub!(/\[/,'')
	definition.gsub!(/\]/,'')
	definition.gsub!(/"/,'')
	definition.gsub!(/,/,'')
	definition.gsub!(/#/,"\n#")
	definition.gsub!(/<\D*\d*>/, '')
	definition.gsub!(/\\\D*\d*\\/, '')
	definition.gsub!(/^#include\s/,'')
	definition.gsub!(/^endif/,"#endif")
  
    return definition
  end
  
  def filename_format(function)
  
    file_name = function[:filename]
	file_name = file_name.gsub(".C",'')
	
	if(file_name.match("EPSGSPACECONV_INTRINSICS"))
	  file_name = "_EPSGSPACECONV"
	elsif(file_name.match("D3EDITOP_INTRINSICS"))
	  file_name = "D3EDITOP_INTRINISCS"
	end
	
    return file_name
  end

end
