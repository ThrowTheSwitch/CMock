
class CMockHeaderParser

  attr_reader :src_lines, :prototypes, :c_attributes
  
  def initialize(parser, source, cfg, name)
    @src_lines = []
    @prototypes = []
    @function_names = []
    @prototype_parse_matcher = /([\d\w\s\*\(\),\[\]]+??)\(([\d\w\s\*\(\),\.\[\]]*)\)$/m

    @c_attributes = cfg.attributes
    @parser = parser
    @name = name
    
    import_source(source)
  end
  
  def parse
    hash = {:functions => []}
    # build prototype list
    extract_prototypes
    # parse all prototyes into hashes of components and add to array
    @prototypes.each do |prototype|
      parsed_hash = parse_prototype(prototype)
      # protect against multiple prototypes (can happen when externs are pulled into preprocessed headers)
      if (!@function_names.include?(parsed_hash[:name]))
        @function_names  << parsed_hash[:name]
        hash[:functions] << parsed_hash
      end
    end
    return hash
  end
  
  private
  
  def import_source(source)
    # look for any edge cases of typedef'd void;
    # void must be void for cmock _ExpectAndReturn calls to process properly.
    # to a certain extent, this action assumes we're chewing on pre-processed header files
    void_types = source.scan(/typedef\s+(\(\s*)?void(\s*\))?\s+([\w\d]+)\s*;/)
    void_types.each {|type| source.gsub!(/#{type}/, 'void')} if void_types.size > 0
    
    source.gsub!(/\s*\\\s*/m, ' ')    # smush multiline statements into single line
    source.gsub!(/\/\*.*?\*\//m, '')  # remove block comments (do it first to avoid trouble with embedded line comments)
    source.gsub!(/\/\/.*$/, '')       # remove line comments
    source.gsub!(/#.*/, '')           # remove preprocessor statements
    source.gsub!(/enum\s*\{[^\}]+\}[^;]*;/m, '')    # remove enum statements (do before typedef removal because an enum can be typedef'd)
    source.gsub!(/union\s*\{[^\}]+\}[^;]*;/m, '')   # remove union statements (do before typedef removal because a union can be typedef'd)
    source.gsub!(/typedef.*/, '')                   # remove typedef statements
    source.gsub!(/\s*=\s*['"a-zA-Z0-9_\.]+\s*/, '') # remove default value statements from argument lists

    source.gsub!(/^\s+/, '')          # remove extra white space from beginning of line
    source.gsub!(/\s+$/, '')          # remove extra white space from end of line
    source.gsub!(/\s*\(\s*/, '(')     # remove extra white space from before left parens
    source.gsub!(/\s*\)\s*/, ')')     # remove extra white space from before right parens
    source.gsub!(/\s+/, ' ')          # remove remaining extra white space

    # split source at end of statements (removing any remaining extra white space)
    @src_lines = source.split(/\s*;\s*/)
    
    # remove function pointer array declarations (they're erroneously recognized as function prototypes);
    # look for something like (* blah [#]) - this can't be a parameter list
    @src_lines.delete_if {|line| !(line =~ /\(\s*\*(.*\[\d*\])??\s*\)/).nil?}
    # remove blank lines
    @src_lines.delete_if {|line| line.strip.length == 0}
  end

  def extract_prototypes
    # build array of function prototypes
    @src_lines.each do |line|
      @prototypes << line if (line =~ @prototype_parse_matcher)
    end
    raise "No function prototypes found in '#{@name}'" if @prototypes.empty?
  end
  
  def parse_prototype(prototype)
    hash = {}
    
    modifiers = []
    @c_attributes.each do |attribute|
      # grab attributes from start of function prototype
      if (prototype =~ /^#{attribute}\s+/i)
        modifiers << attribute
      end
      # remove all modifiers from prototype (start of string as well as in parameter list)
      prototype.gsub!(/#{attribute}\s+/i, '')
    end
    hash[:modifier] = modifiers.join(' ')
    
    parsed = @parser.parse(prototype)

    raise "Failed parsing function prototype: '#{prototype}'" if parsed.nil? 
    
    hash[:name]          = parsed.get_function_name
    hash[:args_string]   = parsed.get_argument_list
    hash[:args]          = parsed.get_arguments
    hash[:return_type]   = parsed.get_return_type
    hash[:return_string] = parsed.get_return_type_with_name
    hash[:var_arg]       = parsed.get_var_arg
    hash[:typedefs]      = parsed.get_typedefs

    return hash
  end

end
