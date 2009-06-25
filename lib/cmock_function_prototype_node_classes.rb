
module CMockFunctionPrototype

  module FunctionPrototypeUtils
    def replace_brackets(string, replace='')
      return string.gsub(/(\s*\[\s*[0-9]*\])+/, replace)
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
      return "#{return_type.text_value} toReturn"
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
      return "#{return_type.text_value} (*toReturn)#{function_return_arglist.normalized_argument_list}"
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
          list << arg.type_and_smart_name_hash(index)
        elsif (arg.class == CMockFunctionPrototype::FunctionPointerNode)
          list << arg.type_and_smart_name_hash(index, self.parent.name.text_value)
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
      name_and_args = get_deepest_name_and_args_node
      return "#{return_type.text_value} (* const #{name_and_args.name.text_value})#{name_and_args.argument_list.normalized_argument_list}" if not (name_and_args.const.text_value.blank?)
      return "#{return_type.text_value} (*#{name_and_args.name.text_value})#{name_and_args.argument_list.normalized_argument_list}"
    end

    def type_and_smart_name_string(arg_list_index)
      name_and_args = get_deepest_name_and_args_node
      func_ptr_name = name_and_args.name.text_value
      
      if (name_and_args.name.text_value.blank?)
        func_ptr_name = make_cmock_arg_name(arg_list_index)
      end

      return "#{return_type.text_value} (* const #{func_ptr_name})#{name_and_args.argument_list.normalized_argument_list}" if not (name_and_args.const.text_value.blank?)
      return "#{return_type.text_value} (*#{func_ptr_name})#{name_and_args.argument_list.normalized_argument_list}"
    end

    def type_and_smart_name_hash(arg_list_index, function_name)
      name_and_args = get_deepest_name_and_args_node
      typename = make_function_pointer_param_typedef_name(arg_list_index, function_name)
            
      return { :type => typename, :name => make_cmock_arg_name(arg_list_index) } if (name_and_args.name.text_value.blank?)    
      return { :type => typename, :name => name_and_args.name.text_value }
    end

    def typedef(arg_list_index, function_name)
      name_and_args = get_deepest_name_and_args_node
      typename = make_function_pointer_param_typedef_name(arg_list_index, function_name)
      
      # don't place 'const' in typedef no matter if it exists or not;
      # data types that comprise mock queues can't be const
      return "typedef #{return_type.text_value} (*#{typename})#{name_and_args.argument_list.normalized_argument_list};"
    end
    
    private
    # dive down into nested parentheses to pull out deepest node info
    def get_deepest_name_and_args_node
      node = name_and_args
      while (node.respond_to?(:name_and_args))
        node = node.name_and_args
      end
      return node
    end
  end


  class TypeWithNameNode < Treetop::Runtime::SyntaxNode
    include FunctionPrototypeUtils

    def text_value
      return "#{type.text_value} #{name.text_value}" if not name.text_value.blank?
      return "#{type.text_value}"
    end

    def type_and_smart_name_string(arg_list_index)
      if (name.text_value.blank?)
        if (type.brackets?)
          return "#{replace_brackets(type.text_value)} #{make_cmock_arg_name(arg_list_index)}#{type.get_brackets}"
        end
        return "#{type.text_value} #{make_cmock_arg_name(arg_list_index)}"
      end

      return "#{type.text_value} #{name.text_value}"
    end

    def type_and_smart_name_hash(arg_list_index)
      if (name.text_value.blank?)
        if (type.brackets?)
          return { :type => replace_brackets(type.text_value_no_const, '*'), :name => make_cmock_arg_name(arg_list_index) }
        end
        return { :type => type.text_value_no_const, :name => make_cmock_arg_name(arg_list_index) }
      end

      if (name.brackets?)
        return { :type => "#{type.text_value_no_const}*", :name => replace_brackets(name.text_value) }
      end

      return { :type => type.text_value_no_const, :name => name.text_value }
    end
  end


  class NameWithBracketsNode < Treetop::Runtime::SyntaxNode
    def text_value
      return super.gsub(/\s+/, '')
    end

    def brackets?
      return !brackets.text_value.blank?
    end

    def get_brackets
      return brackets.text_value
    end
  end


  class NameWithSpaceNode < Treetop::Runtime::SyntaxNode
    def text_value
      return super.strip
    end
  end


  class TypeNode < Treetop::Runtime::SyntaxNode
    include FunctionPrototypeUtils

    def text_value
      type = super
      type.gsub!(/\s+/, ' ')           # remove extra spaces
      type.gsub!(/\s\*/, '*')          # remove space preceding '*'
      type.gsub!(/const\*/, 'const *') # space out 'const' and '*'
      return type.strip
    end

    def text_value_no_const
      return text_value.gsub(/(^|\s+)const($|\s+)/, '')
    end
    
    def brackets?
      return !brackets.text_value.blank?
    end
    
    def get_brackets
      return brackets.text_value
    end
  end
  
  
  class ArrayBracketsNode < Treetop::Runtime::SyntaxNode
    def text_value
      return super.gsub(/\s+/, '')
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
