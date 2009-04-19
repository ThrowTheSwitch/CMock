class CMockHeaderParser

  attr_accessor :src_lines, :funcs, :c_attributes, :included
  
  def initialize(source, cfg)
    import_source(source)
    @funcs = nil
    @c_attributes = cfg.attributes
    @declaration_parse_matcher = /(.*??)\((.*)\)/m
    @included = nil
  end
  
  def parse
    mod = {:includes => nil, :functions => []}
    mod[:includes] = included_files
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

  def parse_functions
    if @funcs.nil?
      @funcs = []
      depth = 0
      @src_lines.each do |line|
        if depth.zero? && line =~ @declaration_parse_matcher
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
      arg_elements = arg.split
      args << {:type => arg_elements[0..-2].join(' '), :name => arg_elements[-1]}
    end
    return args
  end

  def clean_args(arg_list)
    if ((arg_list.strip == 'void') or (arg_list.empty?))
      return 'void'
    else
      c=0
      arg_list.gsub!(/\s+\*/,'*')     #remove space to place asterisks with type (where they belong)
      arg_list.gsub!(/\*(\w)/,'* \1') #pull asterisks away from param to place asterisks with type (where they belong)
      arg_list.split(/\s*,\s*/).map{|arg| (arg =~ /^(\w+|.+\*|.+\)|.+const)$/) ? "#{arg} cmock_arg#{c+=1}" : arg}.join(', ')
    end
  end
  
  def parse_declaration(declaration)
    decl = {}

    regex_match = @declaration_parse_matcher.match(declaration)
    raise "Failed parsing function declaration: '#{declaration}'" if regex_match.nil? 
    
    #grab argument list
    args = regex_match[2].strip

    #process function attributes, return type, and name
    descriptors = regex_match[1]
    descriptors.gsub!(/\s+\*/,'*')     #remove space to place asterisks with return type (where they belong)
    descriptors.gsub!(/\*(\w)/,'* \1') #pull asterisks away from function name to place asterisks with return type (where they belong)
    descriptors = descriptors.split    #array of all descriptor strings

    #grab name
    decl[:name] = descriptors[-1]      #snag name as last array item

    #build attribute and return type strings
    decl[:modifier] = []
    decl[:rettype]  = []    
    descriptors[0..-2].each do |word|
      if @c_attributes.include?(word)
        decl[:modifier] << word
      else
        decl[:rettype]  << word
      end
    end
    decl[:modifier] = decl[:modifier].join(' ')
    decl[:rettype]  = decl[:rettype].join(' ')
        
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
