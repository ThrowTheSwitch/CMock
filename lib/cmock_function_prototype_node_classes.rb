
module CMockFunctionPrototype

  module FunctionPrototypeUtils
    def normalize_ptr(ptr_string)
      ptr_string.gsub!(/\s+\*/, '*')
      ptr_string.gsub!(/\*(\w)/, '* \1')
      return ptr_string
    end

    def make_cmock_arg_name(index)
      return "cmock_arg#{index+1}"
    end
    
    def make_function_pointer_param_typedef_name(arg_list_index, function_name)
      return "FUNC_PTR_#{function_name.upcase}_PARAM_#{arg_list_index+1}_T"
    end    

    def make_function_pointer_return_typedef_name(function_name)
      return "FUNC_PTR_#{function_name.upcase}_RETURN_T"
    end    
  end

  
  class FunctionPrototypeStandardNode < Treetop::Runtime::SyntaxNode
    def get_declaration
      return "#{get_return_type} #{get_function_name}#{argument_list.normalized_argument_list}"
    end
    
    def get_return_type
      return return_type.text_value
    end
    
    # preformatted string for _Return statements e.g. "int toReturn"
    def get_return_type_with_name
      return "#{return_type.text_value} #{CMOCK_RETURN_PARAM_NAME}"
    end

    def get_function_name
      return name.text_value
    end
    
    def get_argument_list
      return argument_list.smart_argument_list
    end
    
    def get_arguments
      return argument_list.arguments_array
    end
    
    def get_var_arg
      return argument_list.var_arg
    end
    
    def get_typedefs
      return argument_list.typedefs_array
    end
  end


  class FunctionPrototypeFunctionPointerReturnNode < Treetop::Runtime::SyntaxNode
    include FunctionPrototypeUtils

    def get_declaration
      return "#{return_type.text_value} (*#{get_function_name}#{function_arglist.normalized_argument_list})#{function_return_arglist.normalized_argument_list}"
    end
    
    def get_return_type
      return make_function_pointer_return_typedef_name(get_function_name)
    end

    # preformatted string for _Return statements e.g. "void (*toReturn)(void)"
    def get_return_type_with_name
      return "#{return_type.text_value} (*#{CMOCK_RETURN_PARAM_NAME})#{function_return_arglist.normalized_argument_list}"
    end
    
    def get_function_name
      return name.text_value
    end
    
    def get_argument_list
      return function_arglist.smart_argument_list
    end
    
    def get_arguments
      return function_arglist.arguments_array
    end
    
    def get_var_arg
      return function_arglist.var_arg
    end
    
    def get_typedefs
      typename = make_function_pointer_return_typedef_name(get_function_name)

      return ["typedef #{return_type.text_value} (*#{typename})#{function_return_arglist.normalized_argument_list};"]
    end
  end


  class ArgumentListNode < Treetop::Runtime::SyntaxNode
    include FunctionPrototypeUtils
    
    def initialize(*params)
      super(*params)
      @var_arg_found = false
    end
    
    def var_arg
      return '...' if @var_arg_found
      return nil
    end

    # produce a simple argument list with pointers and white space normalized
    # (i.e. don't add custom param names, etc.)
    def normalized_argument_list
      list = []
      
      arguments.elements.each do |element|
        list << element.argument.text_value
      end
    
      return '(void)' if (list.size == 0)
      return '(void)' if (list.size == 1 and list[0] == 'void')
      return '( ' + list.join(', ') + ' )'
    end
    
    # produce an argument list with pointers and white space normalized as well as auto-generated names for missing argument names
    def smart_argument_list
      list = []
      
      arguments.elements.each_with_index do |element, index|
        arg = element.argument
        if    (arg.class == CMockFunctionPrototype::TypeWithNameNode)
          list << arg.type_and_smart_name_string(index)
        elsif (arg.class == CMockFunctionPrototype::FunctionPointerNode)
            list << arg.type_and_smart_name_string(index)
        elsif (arg.class == CMockFunctionPrototype::VarArgNode)
          @var_arg_found = true
          # consume var args
        else
          list << arg.text_value
        end
      end

      return 'void' if (list.size == 0)

      return list.join(', ')
    end

    def arguments_array
      list = []
      
      arguments.elements.each_with_index do |element, index|
        arg = element.argument
        if    (arg.class == CMockFunctionPrototype::TypeWithNameNode)
          list << arg.type_and_smart_name_token_hash(index)
        elsif (arg.class == CMockFunctionPrototype::FunctionPointerNode)
          list << arg.type_and_smart_name_token_hash(index, self.parent.name.text_value)
        elsif (arg.class == CMockFunctionPrototype::VarArgNode)
          # consume var args
        elsif (arg.class == CMockFunctionPrototype::VoidNode)
          # consume void
        else
        end
      end
      
      return list
    end
    
    def typedefs_array
      list = []
      
      arguments.elements.each_with_index do |element, index|
        arg = element.argument
        if (arg.class == CMockFunctionPrototype::FunctionPointerNode)
          list << arg.typedef(index, self.parent.name.text_value)
        end
      end
      
      return list      
    end
  end


  class FunctionPointerNode < Treetop::Runtime::SyntaxNode
    include FunctionPrototypeUtils

    def text_value
      return "#{return_type.text_value} (* const #{name.text_value})#{argument_list.normalized_argument_list}" if not (const.text_value.blank?)
      return "#{return_type.text_value} (*#{name.text_value})#{argument_list.normalized_argument_list}"
    end

    def type_and_smart_name_string(arg_list_index)
      func_ptr_name = name.text_value
      
      if (name.text_value.blank?)
        func_ptr_name = make_cmock_arg_name(arg_list_index)
      end

      return "#{return_type.text_value} (* const #{func_ptr_name})#{argument_list.normalized_argument_list}" if not (const.text_value.blank?)
      return "#{return_type.text_value} (*#{func_ptr_name})#{argument_list.normalized_argument_list}"
    end

    def type_and_smart_name_token_hash(arg_list_index, function_name)
      typename = make_function_pointer_param_typedef_name(arg_list_index, function_name)
            
      return { :type => typename, :name => make_cmock_arg_name(arg_list_index) } if (name.text_value.blank?)    
      return { :type => typename, :name => name.text_value }
    end

    def typedef(arg_list_index, function_name)
      typename= make_function_pointer_param_typedef_name(arg_list_index, function_name)
      
      # don't place 'const' in typedef no matter if it exists or not;
      # data types that comprise mock queues can't be const
      return "typedef #{return_type.text_value} (*#{typename})#{argument_list.normalized_argument_list};"
    end
  end


  class TypeWithNameNode < Treetop::Runtime::SyntaxNode
    include FunctionPrototypeUtils

    def text_value
      return "#{normalize_ptr(type.text_value)} #{name.text_value}" if not name.text_value.blank?
      return "#{normalize_ptr(type.text_value)}"
    end

    def type_and_smart_name_string(arg_list_index)
      if (name.text_value.blank?)
        return "#{type.text_value} #{make_cmock_arg_name(arg_list_index)}"
      end

      return "#{type.text_value} #{name.text_value}"
    end

    def type_and_smart_name_token_hash(arg_list_index)
      if (name.text_value.blank?)
        return { :type => type.text_value, :name => make_cmock_arg_name(arg_list_index)}
      end

      return { :type => type.text_value, :name => name.text_value}
    end
  end


  class NameNode < Treetop::Runtime::SyntaxNode
    def text_value
      return super.strip
    end
  end


  class TypeNode < Treetop::Runtime::SyntaxNode
    include FunctionPrototypeUtils

    def text_value
      return normalize_ptr(super.gsub(/\s+/, ' ')).strip
    end
  end
  

  class VoidNode < Treetop::Runtime::SyntaxNode
    def text_value
      return super.strip
    end
  end


  class VarArgNode < Treetop::Runtime::SyntaxNode
    def text_value
      return super.strip
    end
  end

end
