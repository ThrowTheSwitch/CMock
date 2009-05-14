
class CMockHeaderParser

  attr_reader :src_lines, :prototypes, :c_attributes
  
  def initialize(parser, source, cfg)
    @src_lines = []
    @prototypes = []
    @c_attributes = cfg.attributes
    @prototype_parse_matcher = /([\d\w\s\*\(\),]+??)\(([\d\w\s\*\(\),\.]*)\)$/m
    @parser = parser
    import_source(source)
  end
  
  def parse
    hash = {:functions => []}
    # build prototype list
    extract_prototypes
    # parse all prototyes into hashes of components and add to array
    @prototypes.each do |prototype| 
      hash[:functions] << parse_prototype(prototype) if (@prototypes.length > 0)
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
    
    source.gsub!(/\s*\\\s*/m, ' ')    # smush multiline into single line
    source.gsub!(/\/\*.*?\*\//m, '')  # remove block comments (do it first to avoid trouble with embedded line comments)
    source.gsub!(/\/\/.*$/, '')       # remove line comments
    source.gsub!(/#.*/, '')           # remove preprocessor statements
    source.gsub!(/typedef.*/, '')     # remove typedef statements
    source.gsub!(/\s*=\s*['"a-zA-Z0-9_\.]+\s*/, '') # remove default value statements from argument lists

    source.gsub!(/^\s+/, '')          # remove extra white space
    source.gsub!(/\s+$/, '')          # remove extra white space
    source.gsub!(/\s+/, ' ')          # remove extra white space

    @src_lines = source.split(/\s*;\s*/) # split source at end of statements (removing extra white space)
    @src_lines.delete_if {|line| line.strip.length == 0} # remove blank lines
  end

  def extract_prototypes
    # build array of function prototypes
    @src_lines.each do |line|
      @prototypes << line if (line =~ @prototype_parse_matcher)
    end
  end
  
  def parse_prototype(prototype)
    hash = {}
    
    modifiers = []
    @c_attributes.each do |attribute|
      if (prototype =~ /#{attribute}\s+/i)
        modifiers << attribute
        prototype.gsub!(/#{attribute}\s+/i, '')
      end
    end
    hash[:modifier] = modifiers.join(' ')
    
    parsed = @parser.parse(prototype)

    raise "Failed parsing function prototype: '#{prototype}'" if parsed.nil? 
    
    hash[:name]        = parsed.get_function_name
    hash[:args_string] = parsed.get_argument_list
    hash[:args]        = parsed.get_arguments
    hash[:rettype]     = parsed.get_return_type
    hash[:var_arg]     = parsed.get_var_arg

    return hash
  end

end
