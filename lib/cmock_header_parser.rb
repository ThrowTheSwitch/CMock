class CMockHeaderParser

  attr_accessor :match_type, :attribute_match, :src_lines, :funcs, :c_attributes, :declaration_parse_matcher, :included
  
  def initialize(source, match_type=/\w+\**/, attributes=['static', '__monitor', '__ramfunc', '__irq', '__fiq'])
    import_source(source)
    @funcs = nil
    @match_type = match_type
    @c_attributes = attributes
    @declaration_parse_matcher = /(\w*\s+)*([^\s]+)\s+(\w+)\s*\(([^\)]*)\)/
    @included = nil
  end
  
  def parse
    mod = {:includes => nil, :externs => nil, :functions => []}
    mod[:includes] = included_files
    mod[:externs] = externs
    parse_functions
    if !@funcs.nil? and @funcs.length > 0
      @funcs.each do |decl|
        mod[:functions] << parse_declaration(decl)
      end
    end
    return mod
  end
  
  private
  
  def import_source(source)
    source = source.gsub(/\/\/.*$/, '') #remove line comments
    source = source.gsub(/\/\*.*?\*\//m, '') #remove block comments
    @src_lines = source.split(/(^\s*\#.*$)  # Treat preprocessor directives as a logical line
                            | (;|\{|\}) /x) # Match ;, {, and } as end of lines
    @src_lines.delete_if {|line| line.length < 1}
    @src_lines.delete_if {|line| line =~ /\\\n/} #ignore lines that contain continuation lines
    @src_lines.delete_if {|line| line =~ /typedef/i} #ignore lines that contain typedef statements
    @src_lines.delete_if {|line| line =~ /\#define/i}  #remove defines
  end

  def c_attributes=(value)
    @c_attributes = value
    @attribute_match = Regexp.compile(%|(#{@c_attributes.join('|')}\s+)*|)
  end

  def included_files
    if @included.nil?
      @included = []
      if !@src_lines.nil? and @src_lines.length > 0
        @src_lines.each do |line|
          if line =~ /#include\s+"(.*)"/
            @included << $1
          end
        end
      end
    end
    return @included
  end

  def externs
    if !@externs
      @externs = []
      depth = 0
      if !@src_lines.nil? and @src_lines.length > 0
        @src_lines.each do |line|
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
    end
    return @externs
  end

  def parse_functions
    if @funcs.nil?
      @funcs = []
      depth = 0
      @src_lines.each do |line|
        if depth.zero? && line =~ /#{@attribute_match}\s*#{@match_type}\s+\w+\s*\(.*\)/m
          @funcs << line.strip.gsub(/\s+/, ' ')
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
    @funcs ||= @funcs.reject do |func|
      func =~ /\bdefine\b/
    end
    return @funcs
  end
  
  def parse_args(arg_list)
    args = []
    arg_list.split(',').each do |arg|
      arg = arg.strip
      return args if ((arg == '...') || (arg == 'void'))
      arg_match = arg.match /^(.+\s+\*?)(\w+)$/
      raise "Failed parsing argument list at argument: '#{arg}'" if arg_match.nil? 
      args << {:type => arg_match[1].strip.gsub(/\s+\*/,'*'), :name => arg_match[-1].strip}
    end
    return args
  end

  def clean_args(arg_list)
    if ((arg_list.strip == 'void') or (arg_list.empty?))
      return 'void'
    else
      c=0
      arg_list.split(',').map{|arg| (arg.strip =~ /^(\w+|.+\*)\s*$/) ? "#{arg.strip} cmock_arg#{c+=1}" : arg.strip}.join(', ')
    end
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
    
    #put the asterisk with the type (where it belongs)
    if (decl[:name][0] == '*')
      decl[:rettype] << '*'
      decl[:name].slice!(0)
    end
    
    #remove default parameter statements from mock definitions
    args.gsub!(/=\s*[a-zA-Z0-9_\.]+\s*\,/, ',')
    args.gsub!(/=\s*[a-zA-Z0-9_\.]+\s*/, ' ')
    
    #check for var args
    if (args =~ /\.\.\./)
      decl[:var_arg] = args.match( /[\w\s]*\.\.\./ ).to_s.strip
      if (args =~ /\,[\w\s]*\.\.\./)
        args = args.gsub!(/\,[\w\s]*\.\.\./,'')
      else
        args = 'void'
      end
    else
      decl[:var_arg] = nil
    end
    
    args = clean_args(args)
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
