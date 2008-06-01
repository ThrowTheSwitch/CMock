class CFileParser
  attr_accessor :match_type, :attribute_match, :decl_modifier, :decl_return, :decl_function, :decl_args

  def initialize(source, match_type=/\w+\**/, attributes=['static', '__monitor', '__ramfunc', '__irq', '__fiq'])
    source = source.gsub(/\/\/.*$/, '') #remove line comments
    source = source.gsub(/\/\*.*?\*\//m, '') #remove block comments
    @lines = source.split(/(^\s*\#.*$)  # Treat preprocessor directives as a logical line
                            | (;|\{|\}) /x) # Match ;, {, and } as end of lines
    @lines.delete_if {|line| line =~ /\\\n/} #ignore lines that contain continuation lines
    @lines.delete_if {|line| line =~ /typedef/} #ignore lines that contain typedef statements
    
    @functions = nil
    @match_type = match_type
    @c_attributes = attributes
    @declaration_parse_matcher = /(\w*\s+)*([^\s]+)\s+(\w+)\s*\(([^\)]*)\)/
    @attribute_match = Regexp.compile(%|(#{@c_attributes.join('|')}\s+)*|)
    @included = nil
    @var_args_ellipsis = '...'
  end

  def c_attributes=(value)
    @c_attributes = value
    @attribute_match = Regexp.compile(%|(#{@c_attributes.join('|')}\s+)*|)
  end

  def included_files
    if @included.nil?
      @included = []
      @lines.each do |line|
        if line =~ /#include\s+"(.*)"/
          @included << $1
        end
      end
    end
    @included
  end

  def externs
    if !@externs
      @externs = []
      depth = 0
      @lines.each do |line|
        if depth.zero? && line =~ /^\s*extern.*/m
          @externs << $&.strip.gsub(/\s+/, ' ')
        end
        if line =~ /\{/
          depth += 1
        end
        if line =~ /\}/
          depth -= 1
        end
      end
    end
    @externs
  end

  def functions
    if @functions.nil?
      @functions = []
      depth = 0
      @lines.each do |line|
        if depth.zero? && line =~ /#{@attribute_match}\s*#{@match_type}\s+\w+\s*\(.*\)/m
          @functions << line.strip.gsub(/\s+/, ' ')
        end
        if line =~ /\{/
          depth += 1
        end
        if line =~ /\}/
          depth -= 1
        end
      end
    end
    @functions
  end

  def nonstatic_functions
    @nonstatic_functions ||= functions.reject do |func|
      func =~ /\bstatic\b/
    end
  end

  def nondefine_functions
    @nondefine_functions ||= functions.reject do |func|
      func =~ /\bdefine\b/
    end
    @nondefine_functions
  end
  
  def parse_args(arg_list)
    args = []
    arg_list.split(',').each do |arg|
      arg = arg.strip
      return args if ((arg == @var_args_ellipsis) || (arg == 'void'))
      arg_match = arg.match /^(.+)\s+(\w+)$/
      raise "Failed parsing argument list at argument: '#{arg}'" if arg_match.nil?
      type = ''
      name = arg_match[-1]
      type = arg_match[1]
      args << {:name => name, :type => type}
    end
    return args
  end

  def parse_declaration(declaration)
    decl = {}
  
    @declaration_parse_matcher.match(declaration)
    
    modifier = $1 
    modifier = '' if modifier.nil?
    decl[:modifier] = modifier.strip
    
    decl[:return] = $2
    
    decl[:function] = $3
    
    args = $4
    #remove default parameter statements from mock definitions
    args.gsub!(/=\s*[a-zA-Z0-9_\.]+\s*\,/, ',')
    decl_args.gsub!(/=\s*[a-zA-Z0-9_\.]+\s*/, ' ')
    decl_args.strip!
    decl[:args] = decl_args
    
    # ignore variable arguments at end of parameter list
    if (decl_args == @var_args_ellipsis)
      decl[:args_no_var_args] = 'void'
    else
      decl[:args_no_var_args] = decl_args.sub(/,\s*\.\.\./, '')    
    end
      
    if decl[:return].nil? or decl[;function].nil? or decl[:args].nil?
      raise "Declaration parse failed!\n" +
        "  declaration: #{declaration}\n" +
      "  modifier: #{decl[:modifier]}\n" +
      "  return: #{decl[:return]}\n" +
      "  function: #{decl[:function]}\n" +
      "  args:#{decl[:args]}\n" +
      "  args_no_var_args:#{decl[:args_no_var_args]}"
    end
    
    return decl
  end

end
