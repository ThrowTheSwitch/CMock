
class CMockHeaderParser

  attr_reader :src_lines, :prototypes, :attributes
  
  def initialize(parser, source, config, name)
    @src_lines = []
    @prototypes = []
    @function_names = []
    @prototype_parse_matcher = /([\d\w\s\*\(\),\[\]]+??)\(([\d\w\s\*\(\),\.\[\]]*)\)$/m

    @attributes = config.attributes
    @when_no_prototypes = config.when_no_prototypes
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
    if void_types
      void_types = void_types.flatten.uniq - ['(',')',nil]
      void_types.each {|type| source.gsub!(/#{type}/, 'void')} if void_types.size > 0
    end
    
    source.gsub!(/\s*\\\s*/m, ' ')    # smush multiline statements into single line
    source.gsub!(/\/\*.*?\*\//m, '')  # remove block comments (do it first to avoid trouble with embedded line comments)
    source.gsub!(/\/\/.*$/, '')       # remove line comments
    source.gsub!(/#.*/, '')           # remove preprocessor statements

    # unions, structs, and typedefs can all contain things (e.g. function pointers) that parse like function prototypes, so yank them;
    # enums might cause trouble or might not - pull 'em just to be safe
    source.gsub!(/^[\w\s]*enum[\w\s]*\{[^\}]+\}[\w\s]*;/m, '')   # remove enum definitions
    source.gsub!(/^[\w\s]*union[\w\s]*\{[^\}]+\}[\w\s]*;/m, '')  # remove union definitions
    source.gsub!(/^[\w\s]*struct[^;\{\}\(\)]+;/m, '')            # remove forward declared structs but leave function prototypes having struct in types
                                                                 # (do before struct definitions so as to not mess up recognizing full struct definitions)
    source.gsub!(/^[\w\s]*struct[\w\s]*\{[^\}]+\}[\w\s]*;/m, '') # remove struct definitions
    
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
    # look for something like (* blah [#]) - this can't be a function parameter list
    @src_lines.delete_if {|line| !(line =~ /\(\s*\*(.*\[\d*\])??\s*\)/).nil?}
    # remove functions that are externed - mocking an extern'd function in a header file is a weird condition
    @src_lines.delete_if {|line| !(line =~ /(^|\s+)extern\s+/).nil?}
    # remove functions that are inlined - mocking an inine function will either break compilation or lead to other oddities
    @src_lines.delete_if {|line| !(line =~ /(^|\s+)inline\s+/).nil?}
    # remove blank lines
    @src_lines.delete_if {|line| line.strip.length == 0}
  end

  def extract_prototypes
    # build array of function prototypes
    @src_lines.each do |line|
      @prototypes << line if (line =~ @prototype_parse_matcher)
    end
    if @prototypes.empty?
      case @when_no_prototypes
        when :error
          raise "ERROR: No function prototypes found in '#{@name}'" 
        when :warn
          puts "WARNING: No function prototypes found in '#{@name}'"
      end
    end
  end
  
  def parse_prototype(prototype)
    hash = {}
    
    modifiers = []
    # grab special attributes from function prototype and remove them from prototype
    @attributes.each do |attribute|
      if (prototype =~ /#{attribute}\s+/)
        modifiers << attribute
        prototype.gsub!(/#{attribute}\s+/, '')
      end
    end
    hash[:modifier] = modifiers.join(' ')

    # excise these keywords from prototype (entire 'inline' and 'extern' prototypes are already gone)
    ['auto', 'register', 'static', 'restrict', 'volatile'].each do |keyword|
      prototype.gsub!(/(,\s*|\(\s*|\*\s*|^\s*|\s+)#{keyword}\s*(,|\)|\w)/, "\\1\\2")
    end
    
    parsed = @parser.parse(prototype)

    raise "Failed parsing function prototype: '#{prototype}' in file '#{@name}'" if parsed.nil? 
    
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
