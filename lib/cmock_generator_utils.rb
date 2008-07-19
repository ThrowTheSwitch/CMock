
class CMockGeneratorUtils

  def initialize(config)
    @config = config
	  @tab = @config.tab
  end
  
  def create_call_list(args)
    call_list = ""
    args.each do |arg|
      if call_list.empty?
        call_list = arg[:name]
      else
        call_list += ", " + arg[:name]
      end
    end
    return call_list
  end
  
  def make_expand_array(type, array, newValue)
    lines = ["\n"]
    lines << "#{@tab}{\n"
    lines << "#{@tab}#{@tab}int sz = 0;\n"
    lines << "#{@tab}#{@tab}#{type} *pointer = #{array};\n"
    lines << "#{@tab}#{@tab}while(pointer && pointer != #{array}Tail) { sz++; pointer++; }\n"
    lines << "#{@tab}#{@tab}if(sz == 0)\n"
    lines << "#{@tab}#{@tab}{\n"
    lines << "#{@tab}#{@tab}#{@tab}#{array} = (#{type}*)malloc(2*sizeof(#{type}));\n"
    lines << "#{@tab}#{@tab}#{@tab}if(!#{array})\n"
    lines << "#{@tab}#{@tab}#{@tab}#{@tab}Mock.allocFailure++;\n"
    lines << "#{@tab}#{@tab}}\n"
    lines << "#{@tab}#{@tab}else\n"
    lines << "#{@tab}#{@tab}{\n"
    lines << "#{@tab}#{@tab}#{@tab}#{type} *ptmp = (#{type}*)realloc(#{array}, sizeof(#{type}) * (sz+1));\n"
    lines << "#{@tab}#{@tab}#{@tab}if(!ptmp)\n"
    lines << "#{@tab}#{@tab}#{@tab}#{@tab}Mock.allocFailure++;\n"
    lines << "#{@tab}#{@tab}#{@tab}else\n"
    lines << "#{@tab}#{@tab}#{@tab}#{@tab}#{array} = ptmp;\n"
    lines << "#{@tab}#{@tab}}\n"
    lines << "#{@tab}#{@tab}memcpy(&#{array}[sz], &#{newValue}, sizeof(#{type}));\n"
    lines << "#{@tab}#{@tab}#{array}Tail = &#{array}[sz+1];\n"
    lines << "#{@tab}}\n"
  end
  
  def make_handle_return(function_name, function_return_type, indent)
    lines = ["\n"]
    lines << "#{indent}if(Mock.#{function_name}_Return != Mock.#{function_name}_Return_HeadTail)\n"
    lines << "#{indent}{\n"
    lines << "#{indent}#{@tab}#{function_return_type} toReturn = *Mock.#{function_name}_Return;\n"
    lines << "#{indent}#{@tab}Mock.#{function_name}_Return++;\n"
    lines << "#{indent}#{@tab}return toReturn;\n"
    lines << "#{indent}}\n"
    lines << "#{indent}else\n"
    lines << "#{indent}{\n"
    lines << "#{indent}#{@tab}return *Mock.#{function_name}_Return_Head;\n"
    lines << "#{indent}}\n"
  end
end