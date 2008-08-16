class CMockHeaderParser

  attr_accessor :match_type, :attribute_match, :decl_modifier, :decl_return, :decl_function, :decl_args

  def initialize(source, match_type=/\w+\**/, attributes=['static', '__monitor', '__ramfunc', '__irq', '__fiq'])
    source = source.gsub(/\/\/.*$/, '') #remove line comments
    source = source.gsub(/\/\*.*?\*\//m, '') #remove block comments
    @lines = source.split(/(^\s*\#.*$)  # Treat preprocessor directives as a logical line
                            | (;|\{|\}) /x) # Match ;, {, and } as end of lines
    @lines.delete_if {|line| line =~ /\\\n/} #ignore lines that contain continuation lines
    @lines.delete_if {|line| line =~ /typedef/} #ignore lines that contain typedef statements
    @lines.delete_if {|line| line =~ /\#define/}  #remove defines
    
    @functions = nil
    @match_type = match_type
    @c_attributes = attributes
    @declaration_parse_matcher = /(\w*\s+)*([^\s]+)\s+(\w+)\s*\(([^\)]*)\)/
    @included = nil
    @var_args_ellipsis = '...'
  end
  
  def parse
    mod = {:includes => nil, :externs => nil, :functions => []}
    mod[:includes] = included_files
    mod[:externs] = externs
    functions.each do |decl|
      mod[:functions] << parse_declaration(decl)
    end
    return mod
  end
  
  private

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
    return @included
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
    return @externs
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
    #eliminate define functions
    @functions ||= functions.reject do |func|
      func =~ /\bdefine\b/
    end
    return @functions
  end
  
  def parse_args(arg_list)
    args = []
    arg_list.split(',').each do |arg|
      arg = arg.strip
      return args if ((arg == @var_args_ellipsis) || (arg == 'void'))
      arg_match = arg.match /^(.+)\s+(\*?\w+)$/
      raise "Failed parsing argument list at argument: '#{arg}'" if arg_match.nil?
      
      #put the asterix with the type (where it belongs)
      if (arg_match[-1][0] == '*')
        arg_match[1] << '*'
        arg_match[-1].slice!(0)
      end
      
      args << {:type => arg_match[1], :name => arg_match[-1]}
    end
    return args
  end

  def parse_declaration(declaration)
    decl = {}
  
    @declaration_parse_matcher.match(declaration)
    
    modifier = $1 
    modifier = '' if modifier.nil?
    decl[:modifier] = modifier.strip
    decl[:rettype] = $2
    decl[:name] = $3
    
    args = $4
    #remove default parameter statements from mock definitions
    args.gsub!(/=\s*[a-zA-Z0-9_\.]+\s*\,/, ',')
    args.gsub!(/=\s*[a-zA-Z0-9_\.]+\s*/, ' ')
    
    #check for var args
    if (args =~ /\.\.\./)
      decl[:var_arg] = args.match( /[\w\s]*\.\.\./ ).to_s
      if (args =~ /\,[\w\s]*\.\.\./)
        args = args.gsub!(/\,[\w\s]*\.\.\./,'')
      else
        args = 'void'
      end
    else
      decl[:var_arg] = nil
    end
    
    args.strip!
    decl[:args_string] = args
    decl[:args] = parse_args(args)
      
    if decl[:rettype].nil? or decl[:name].nil? or decl[:args].nil?
      raise "Declaration parse failed!\n" +
        "  declaration: #{declaration}\n" +
        "  modifier: #{decl[:modifier]}\n" +
        "  return: #{decl[:rettype]}\n" +
        "  function: #{decl[:name]}\n" +
        "  args:#{decl[:args]}\n"
    end
    
    return decl
  end

end
