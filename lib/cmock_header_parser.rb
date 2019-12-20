# ==========================================
#   CMock Project - Automatic Mock Generation for C
#   Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
#   [Released under MIT License. Please refer to license.txt for details]
# ==========================================

class CMockHeaderParser

  attr_accessor :funcs, :c_attr_noconst, :c_attributes, :treat_as_void, :treat_externs, :treat_inlines, :inline_function_patterns

  def initialize(cfg)
    @funcs = []
    @c_strippables = cfg.strippables
    @c_attr_noconst = cfg.attributes.uniq - ['const']
    @c_attributes = ['const'] + c_attr_noconst
    @c_calling_conventions = cfg.c_calling_conventions.uniq
    @treat_as_array = cfg.treat_as_array
    @treat_as_void = (['void'] + cfg.treat_as_void).uniq
    @declaration_parse_matcher = /([\d\w\s\*&\(\),\[\]]+??)\(([\d\w\s\*&\(\),\.\[\]+-]*)\)$/m
    @standards = (['int','short','char','long','unsigned','signed'] + cfg.treat_as.keys).uniq
    @array_size_name = cfg.array_size_name
    @array_size_type = (['int', 'size_t'] + cfg.array_size_type).uniq
    @when_no_prototypes = cfg.when_no_prototypes
    @local_as_void = @treat_as_void
    @verbosity = cfg.verbosity
    @treat_externs = cfg.treat_externs
    @treat_inlines = cfg.treat_inlines
    @inline_function_patterns = cfg.inline_function_patterns
    @c_strippables += ['extern'] if (@treat_externs == :include) #we'll need to remove the attribute if we're allowing externs
    @c_strippables += ['inline'] if (@treat_inlines == :include) #we'll need to remove the attribute if we're allowing inlines
  end

  def parse(name, source)
    @module_name = name.gsub(/\W/,'')
    @typedefs = []
    @funcs = []
    @normalized_source = nil
    function_names = []

    tmp_funcs = parse_functions( import_source(source) ).map do |item| [item, []] end
    tmp_funcs += parse_cpp_functions( import_cpp_source(source) )
    tmp_funcs.map do |decl|
      func = parse_declaration(decl[0], decl.length > 1 ? decl[1] : [], decl.length > 2 ? decl[2] : nil)
      unless (function_names.include? func[:name])
        @funcs << func
        function_names << func[:name]
      end
    end

    @normalized_source = if (@treat_inlines == :include)
                           transform_inline_functions(source)
                         else
                           ''
                         end

    { :includes  => nil,
      :functions => @funcs,
      :typedefs  => @typedefs,
      :normalized_source    => @normalized_source
    }
  end

  private if $ThisIsOnlyATest.nil? ################

  def remove_nested_pairs_of_braces(source)
    # remove nested pairs of braces because no function declarations will be inside of them (leave outer pair for function definition detection)
    if (RUBY_VERSION.split('.')[0].to_i > 1)
      #we assign a string first because (no joke) if Ruby 1.9.3 sees this line as a regex, it will crash.
      r = "\\{([^\\{\\}]*|\\g<0>)*\\}"
      source.gsub!(/#{r}/m, '{ }')
    else
      while source.gsub!(/\{[^\{\}]*\{[^\{\}]*\}[^\{\}]*\}/m, '{ }')
      end
    end

    return source
  end

  # Return the number of pairs of braces/square brackets in the function provided by the user
  # +source+:: String containing the function to be processed
  def count_number_of_pairs_of_braces_in_function(source)
    is_function_start_found = false
    curr_level = 0
    total_pairs = 0

    source.each_char do |c|
      if ("{" == c)
        curr_level += 1
        total_pairs  +=1
        is_function_start_found = true
      elsif ("}" == c)
        curr_level -=1
      end

      break if is_function_start_found && curr_level == 0    # We reached the end of the inline function body
    end

    if 0 != curr_level
      total_pairs = 0          # Something is fishy about this source, not enough closing braces?
    end

    return total_pairs
  end

  # Transform inline functions to regular functions in the source by the user
  # +source+:: String containing the source to be processed
  def transform_inline_functions(source)
    inline_function_regex_formats = []
    square_bracket_pair_regex_format = /\{[^\{\}]*\}/ # Regex to match one whole block enclosed by two square brackets

    # Convert user provided string patterns to regex
    @inline_function_patterns.each do |user_format_string|
      user_regex = Regexp.new(user_format_string)
      cleanup_spaces_after_user_regex = /\s*/
      inline_function_regex_formats << Regexp.new(user_regex.source + cleanup_spaces_after_user_regex.source)
    end

    # let's clean up the encoding in case they've done anything weird with the characters we might find
    source = source.force_encoding("ISO-8859-1").encode("utf-8", :replace => nil)

    # - Just looking for static|inline in the gsub is a bit too aggressive (functions that are named like this, ...), so we try to be a bit smarter
    #   Instead, look for "static inline" and parse it:
    #   - Everything before the match should just be copied, we don't want
    #     to touch anything but the inline functions.
    #   - Remove the implementation of the inline function (this is enclosed
    #     in square brackets) and replace it with ";" to complete the
    #     transformation to normal/non-inline function.
    #     To ensure proper removal of the function body, we count the number of square-bracket pairs
    #     and remove the pairs one-by-one.
    #   - Copy everything after the inline function implementation and start the parsing of the next inline function

    inline_function_regex_formats.each do |format|
      loop do
        inline_function_match = source.match(/#{format}/) # Search for inline function declaration
        break if nil == inline_function_match             # No inline functions so nothing to do

        total_pairs_to_remove = count_number_of_pairs_of_braces_in_function(inline_function_match.post_match)

        break if 0 == total_pairs_to_remove # Bad source?

        inline_function_stripped = inline_function_match.post_match

        total_pairs_to_remove.times do
          inline_function_stripped.sub!(/\s*#{square_bracket_pair_regex_format}/, ";") # Remove inline implementation (+ some whitespace because it's prettier)
        end

        source = inline_function_match.pre_match + inline_function_stripped # Make new source with the inline function removed and move on to the next
      end
    end

    return source
  end

  def import_source(source)

    # let's clean up the encoding in case they've done anything weird with the characters we might find
    source = source.force_encoding("ISO-8859-1").encode("utf-8", :replace => nil)

    # void must be void for cmock _ExpectAndReturn calls to process properly, not some weird typedef which equates to void
    # to a certain extent, this action assumes we're chewing on pre-processed header files, otherwise we'll most likely just get stuff from @treat_as_void
    @local_as_void = @treat_as_void
    void_types = source.scan(/typedef\s+(?:\(\s*)?void(?:\s*\))?\s+([\w]+)\s*;/)
    if void_types
      @local_as_void += void_types.flatten.uniq.compact
    end

    # If user wants to mock inline functions,
    # remove the (user specific) inline keywords before removing anything else to avoid missing an inline function
    if (@treat_inlines == :include)
      @inline_function_patterns.each { |user_format_string|
        source.gsub!(/#{user_format_string}/, '') # remove user defined inline function patterns
      }
    end

    # smush multiline macros into single line (checking for continuation character at end of line '\')
    source.gsub!(/\s*\\\s*/m, ' ')

    #remove comments (block and line, in three steps to ensure correct precedence)
    source.gsub!(/(?<!\*)\/\/(?:.+\/\*|\*(?:$|[^\/])).*$/, '')  # remove line comments that comment out the start of blocks
    source.gsub!(/\/\*.*?\*\//m, '')                            # remove block comments
    source.gsub!(/\/\/.*$/, '')                                 # remove line comments (all that remain)

    # remove assembler pragma sections
    source.gsub!(/^\s*#\s*pragma\s+asm\s+.*?#\s*pragma\s+endasm/m, '')

    # remove gcc's __attribute__ tags
    source.gsub!(/__attribute(?:__)?\s*\(\(+.*\)\)+/, '')

    # remove preprocessor statements and extern "C"
    source.gsub!(/^\s*#.*/, '')
    source.gsub!(/extern\s+\"C\"\s*\{/, '')

    # enums, unions, structs, and typedefs can all contain things (e.g. function pointers) that parse like function prototypes, so yank them
    # forward declared structs are removed before struct definitions so they don't mess up real thing later. we leave structs keywords in function prototypes
    source.gsub!(/^[\w\s]*struct[^;\{\}\(\)]+;/m, '')                                      # remove forward declared structs
    source.gsub!(/^[\w\s]*(enum|union|struct|typedef)[\w\s]*\{[^\}]+\}[\w\s\*\,]*;/m, '')  # remove struct, union, and enum definitions and typedefs with braces
    source.gsub!(/(\W)(?:register|auto|static|restrict)(\W)/, '\1\2')                      # remove problem keywords
    source.gsub!(/\s*=\s*['"a-zA-Z0-9_\.]+\s*/, '')                                        # remove default value statements from argument lists
    source.gsub!(/^(?:[\w\s]*\W)?typedef\W[^;]*/m, '')                                     # remove typedef statements
    source.gsub!(/\)(\w)/, ') \1')                                                         # add space between parenthese and alphanumeric
    source.gsub!(/(^|\W+)(?:#{@c_strippables.join('|')})(?=$|\W+)/,'\1') unless @c_strippables.empty? # remove known attributes slated to be stripped

    #scan standalone function pointers and remove them, because they can just be ignored
    source.gsub!(/\w+\s*\(\s*\*\s*\w+\s*\)\s*\([^)]*\)\s*;/,';')

    #scan for functions which return function pointers, because they are a pain
    source.gsub!(/([\w\s\*]+)\(*\(\s*\*([\w\s\*]+)\s*\(([\w\s\*,]*)\)\)\s*\(([\w\s\*,]*)\)\)*/) do |m|
      functype = "cmock_#{@module_name}_func_ptr#{@typedefs.size + 1}"
      @typedefs << "typedef #{$1.strip}(*#{functype})(#{$4});"
      "#{functype} #{$2.strip}(#{$3});"
    end

    source = remove_nested_pairs_of_braces(source)

    if (@treat_inlines == :include)
      # Functions having "{ }" at this point are/were inline functions,
      # User wants them in so 'disguise' them as normal functions with the ";"
      source.gsub!("{ }", ";")
    end


    # remove function definitions by stripping off the arguments right now
    source.gsub!(/\([^\)]*\)\s*\{[^\}]*\}/m, ";")

    #drop extra white space to make the rest go faster
    source.gsub!(/^\s+/, '')          # remove extra white space from beginning of line
    source.gsub!(/\s+$/, '')          # remove extra white space from end of line
    source.gsub!(/\s*\(\s*/, '(')     # remove extra white space from before left parens
    source.gsub!(/\s*\)\s*/, ')')     # remove extra white space from before right parens
    source.gsub!(/\s+/, ' ')          # remove remaining extra white space

    #split lines on semicolons and remove things that are obviously not what we are looking for
    src_lines = source.split(/\s*;\s*/).uniq
    src_lines.delete_if {|line| line.strip.length == 0}                            # remove blank lines
    src_lines.delete_if {|line| !(line =~ /[\w\s\*]+\(+\s*\*[\*\s]*[\w\s]+(?:\[[\w\s]*\]\s*)+\)+\s*\((?:[\w\s\*]*,?)*\s*\)/).nil?}     #remove function pointer arrays

    unless (@treat_externs == :include)
      src_lines.delete_if {|line| !(line =~ /(?:^|\s+)(?:extern)\s+/).nil?} # remove extern functions
    end

    unless (@treat_inlines == :include)
      src_lines.delete_if {|line| !(line =~ /(?:^|\s+)(?:inline)\s+/).nil?} # remove inline functions
    end

    src_lines.delete_if {|line| line.empty? } #drop empty lines
  end

  def import_cpp_source(source)
    # let's clean up the encoding in case they've done anything weird with the characters we might find
    source = source.force_encoding("ISO-8859-1").encode("utf-8", :replace => nil)

    # void must be void for cmock _ExpectAndReturn calls to process properly, not some weird typedef which equates to void
    # to a certain extent, this action assumes we're chewing on pre-processed header files, otherwise we'll most likely just get stuff from @treat_as_void
    @local_as_void = @treat_as_void
    void_types = source.scan(/typedef\s+(?:\(\s*)?void(?:\s*\))?\s+([\w\d]+)\s*;/)
    if void_types
      @local_as_void += void_types.flatten.uniq.compact
    end

    # smush multiline macros into single line (checking for continuation character at end of line '\')
    source.gsub!(/\s*\\\s*/m, ' ')

    #remove comments (block and line, in three steps to ensure correct precedence)
    source.gsub!(/(?<!\*)\/\/(?:.+\/\*|\*(?:$|[^\/])).*$/, '')  # remove line comments that comment out the start of blocks
    source.gsub!(/\/\*.*?\*\//m, '')                            # remove block comments
    source.gsub!(/\/\/.*$/, '')                                 # remove line comments (all that remain)

    # remove assembler pragma sections
    source.gsub!(/^\s*#\s*pragma\s+asm\s+.*?#\s*pragma\s+endasm/m, '')

    # remove gcc's __attribute__ tags
    source.gsub!(/__attribute(?:__)?\s*\(\(+.*\)\)+/, '')

    # remove preprocessor statements and extern "C"
    source.gsub!(/^\s*#.*/, '')
    source.gsub!(/extern\s+\"C\"\s*\{/, '')
=begin
    # enums, unions, structs, and typedefs can all contain things (e.g. function pointers) that parse like function prototypes, so yank them
    # forward declared structs are removed before struct definitions so they don't mess up real thing later. we leave structs keywords in function prototypes
    source.gsub!(/^[\w\s]*struct[^;\{\}\(\)]+;/m, '')                                      # remove forward declared structs
    source.gsub!(/^[\w\s]*(enum|union|struct|typedef)[\w\s]*\{[^\}]+\}[\w\s\*\,]*;/m, '')  # remove struct, union, and enum definitions and typedefs with braces
    source.gsub!(/(\W)(?:register|auto|static|restrict)(\W)/, '\1\2')                      # remove problem keywords
    source.gsub!(/\s*=\s*['"a-zA-Z0-9_\.]+\s*/, '')                                        # remove default value statements from argument lists
=end
    source.gsub!(/^(?:[\w\s]*\W)?typedef\W[^;]*/m, '')                                     # remove typedef statements
    source.gsub!(/\)(\w)/, ') \1')                                                         # add space between parenthese and alphanumeric
    source.gsub!(/(^|\W+)(?:#{@c_strippables.join('|')})(?=$|\W+)/,'\1') unless @c_strippables.empty? # remove known attributes slated to be stripped

    #scan standalone function pointers and remove them, because they can just be ignored
    source.gsub!(/\w+\s*\(\s*\*\s*\w+\s*\)\s*\([^)]*\)\s*;/,';')

    #scan for functions which return function pointers, because they are a pain
    source.gsub!(/([\w\s\*]+)\(*\(\s*\*([\w\s\*]+)\s*\(([\w\s\*,]*)\)\)\s*\(([\w\s\*,]*)\)\)*/) do |m|
      functype = "cmock_#{@module_name}_func_ptr#{@typedefs.size + 1}"
      # already done when parsing C functions
      #@typedefs << "typedef #{$1.strip}(*#{functype})(#{$4});"
      "#{functype} #{$2.strip}(#{$3});"
    end
=begin
    # remove nested pairs of braces because no function declarations will be inside of them (leave outer pair for function definition detection)
    if (RUBY_VERSION.split('.')[0].to_i > 1)
      #we assign a string first because (no joke) if Ruby 1.9.3 sees this line as a regex, it will crash.
      r = "\\{([^\\{\\}]*|\\g<0>)*\\}"
      source.gsub!(/#{r}/m, '{ }')
    else
      while source.gsub!(/\{[^\{\}]*\{[^\{\}]*\}[^\{\}]*\}/m, '{ }')
      end
    end
=end
    # remove function definitions by stripping off the arguments right now
    source.gsub!(/\([^\)]*\)\s*\{[^\}]*\}/m, ";")

    #drop extra white space to make the rest go faster
    source.gsub!(/^\s+/, '')          # remove extra white space from beginning of line
    source.gsub!(/\s+$/, '')          # remove extra white space from end of line
    source.gsub!(/\s*\(\s*/, '(')     # remove extra white space from before left parens
    source.gsub!(/\s*\)\s*/, ')')     # remove extra white space from before right parens
    source.gsub!(/\s+/, ' ')          # remove remaining extra white space

    #split lines on semicolons and remove things that are obviously not what we are looking for
    src_lines = source.split(/\s*;\s*/).uniq
    src_lines.delete_if {|line| line.strip.length == 0}                            # remove blank lines
    src_lines.delete_if {|line| !(line =~ /[\w\s\*]+\(+\s*\*[\*\s]*[\w\s]+(?:\[[\w\s]*\]\s*)+\)+\s*\((?:[\w\s\*]*,?)*\s*\)/).nil?}     #remove function pointer arrays
    if (@treat_externs == :include)
      src_lines.delete_if {|line| !(line =~ /(?:^|\s+)(?:inline)\s+/).nil?}        # remove inline functions
    else
      src_lines.delete_if {|line| !(line =~ /(?:^|\s+)(?:extern|inline)\s+/).nil?} # remove inline and extern functions
    end
    src_lines.delete_if {|line| line.empty? } #drop empty lines
  end

  def parse_cpp_functions(source)
    funcs = []

    # simple parse, does not handle comments (and probably many other potential issues)
    braces = 0
    ns = []
    cls = ''
    pub = false
    source.each do |line|

      # TODO add support for nested classes and functions in a namespace but not a class
      name_or_class = line.scan(/(?:\s*(?:namespace|class)\s+(\S+)\s+{)/)
      line.scan(/(?:\s*(?:namespace)\s+(\S+)\s+{)/).each{ |item| ns << item[0] }
      line.scan(/(?:\s*(?:class)\s+(\S+)\s+{)/).each{ |item| cls = item[0] }

      braces += line.scan('{').length - name_or_class.length
      close = line.scan('}').length
      if close > 0
        if close > braces
          ns.pop(close - braces)
          braces = 0
        else
          braces -= close
        end
      end

      pub = true if line =~ /public:/
      pub = false if line =~ /private:/ or line =~ /protected:/

      if pub
        if line =~ /^\s*static\s+/
          line.sub!('static', '')
          if (line =~ @declaration_parse_matcher)
            # TODO add support for nested classes and functions in a namespace but not a class
            funcs << [line.strip.gsub(/\s+/, ' '), ns.dup, cls]
          end
        end
      end
    end
    return funcs
  end

  def parse_functions(source)
    funcs = []
    source.each {|line| funcs << line.strip.gsub(/\s+/, ' ') if (line =~ @declaration_parse_matcher)}
    if funcs.empty?
      case @when_no_prototypes
        when :error
          raise "ERROR: No function prototypes found!"
        when :warn
          puts "WARNING: No function prototypes found!" unless (@verbosity < 1)
      end
    end
    return funcs
  end

  def parse_type_and_name(arg)
    # Split up words and remove known attributes.  For pointer types, make sure
    # to remove 'const' only when it applies to the pointer itself, not when it
    # applies to the type pointed to.  For non-pointer types, remove any
    # occurrence of 'const'.
    arg.gsub!(/(\w)(\*|&)/,'\1 \2') # pull asterisks away from preceding word
    arg.gsub!(/(\*|&)(\w)/,'\1 \2') # pull asterisks away from following word
    arg_array = arg.split
    arg_info = divine_ptr_and_const(arg)
    arg_info[:name] = arg_array[-1]

    attributes = (arg.include?('*') or arg.include?('&')) ? @c_attr_noconst : @c_attributes
    attr_array = []
    type_array = []

    arg_array[0..-2].each do |word|
      if attributes.include?(word)
        attr_array << word
      elsif @c_calling_conventions.include?(word)
        arg_info[:c_calling_convention] = word
      else
        type_array << word
      end
    end

    if arg_info[:const_ptr?]
      attr_array << 'const'
      type_array.delete_at(type_array.rindex('const'))
    end

    arg_info[:modifier] = attr_array.join(' ')
    arg_info[:type] = type_array.join(' ').gsub(/\s+\*/,'*').gsub(/\s+&/,'&') # remove space before asterisks
    return arg_info
  end

  def parse_args(arg_list)
    args = []
    arg_list.split(',').each do |arg|
      arg.strip!
      return args if (arg =~ /^\s*((\.\.\.)|(void))\s*$/)   # we're done if we reach void by itself or ...

      arg_info = parse_type_and_name(arg)
      arg_info.delete(:modifier)             # don't care about this
      arg_info.delete(:c_calling_convention) # don't care about this

      # in C, array arguments implicitly degrade to pointers
      # make the translation explicit here to simplify later logic
      if @treat_as_array[arg_info[:type]] and not arg_info[:ptr?] then
        arg_info[:type] = "#{@treat_as_array[arg_info[:type]]}*"
        arg_info[:type] = "const #{arg_info[:type]}" if arg_info[:const?]
        arg_info[:ptr?] = true
      end

      args << arg_info
    end

    # Try to find array pair in parameters following this pattern : <type> * <name>, <@array_size_type> <@array_size_name>
    args.each_with_index {|val, index|
      next_index = index + 1
      if (args.length > next_index)
        if (val[:ptr?] == true and args[next_index][:name].match(@array_size_name) and @array_size_type.include?(args[next_index][:type]))
          val[:array_data?] = true
          args[next_index][:array_size?] = true
        end
      end
    }

    return args
  end

  def divine_ptr(arg)
    return false unless arg.include? '*'
    # treat "const char *" and similar as a string, not a pointer
    return false if /(^|\s)(const\s+)?char(\s+const)?\s*\*(?!.*\*)/ =~ arg
    return true
  end

  def divine_const(arg)
    # a non-pointer arg containing "const" is a constant
    # an arg containing "const" before the last * is a pointer to a constant
    return ( arg.include?('*') ? (/(^|\s|\*)const(\s(\w|\s)*)?\*(?!.*\*)/ =~ arg)
                               : (/(^|\s)const(\s|$)/ =~ arg) ) ? true : false
  end

  def divine_ptr_and_const(arg)
    divination = {}

    divination[:ptr?] = divine_ptr(arg)
    divination[:const?] = divine_const(arg)

    # an arg containing "const" after the last * is a constant pointer
    divination[:const_ptr?] = (/\*(?!.*\*)\s*const(\s|$)/ =~ arg) ? true : false

    return divination
  end

  def clean_args(arg_list)
    if ((@local_as_void.include?(arg_list.strip)) or (arg_list.empty?))
      return 'void'
    else
      c = 0
      # magically turn brackets into asterisks, also match for parentheses that come from macros
      arg_list.gsub!(/(\w+)(?:\s*\[[\s\w\(\)+-]*\])+/, '*\1')
      # remove space to place asterisks with type (where they belong)
      arg_list.gsub!(/\s+\*/, '*')
      # pull asterisks away from arg to place asterisks with type (where they belong)
      arg_list.gsub!(/\*(\w)/, '* \1')

      # scan argument list for function pointers and replace them with custom types
      arg_list.gsub!(/([\w\s\*]+)\(+\s*\*[\*\s]*([\w\s]*)\s*\)+\s*\(((?:[\w\s\*]*,?)*)\s*\)*/) do |m|

        functype = "cmock_#{@module_name}_func_ptr#{@typedefs.size + 1}"
        funcret  = $1.strip
        funcname = $2.strip
        funcargs = $3.strip
        funconst = ''
        if (funcname.include? 'const')
          funcname.gsub!('const','').strip!
          funconst = 'const '
        end
        @typedefs << "typedef #{funcret}(*#{functype})(#{funcargs});"
        funcname = "cmock_arg#{c+=1}" if (funcname.empty?)
        "#{functype} #{funconst}#{funcname}"
      end

      #scan argument list for function pointers with shorthand notation and replace them with custom types
      arg_list.gsub!(/([\w\s\*]+)+\s+(\w+)\s*\(((?:[\w\s\*]*,?)*)\s*\)*/) do |m|

        functype = "cmock_#{@module_name}_func_ptr#{@typedefs.size + 1}"
        funcret  = $1.strip
        funcname = $2.strip
        funcargs = $3.strip
        funconst = ''
        if (funcname.include? 'const')
          funcname.gsub!('const','').strip!
          funconst = 'const '
        end
        @typedefs << "typedef #{funcret}(*#{functype})(#{funcargs});"
        funcname = "cmock_arg#{c+=1}" if (funcname.empty?)
        "#{functype} #{funconst}#{funcname}"
      end

      #automatically name unnamed arguments (those that only had a type)
      arg_list.split(/\s*,\s*/).map { |arg|
        parts = (arg.split - ['struct', 'union', 'enum', 'const', 'const*'])
        if ((parts.size < 2) or (parts[-1][-1].chr == '*') or (@standards.include?(parts[-1])))
          "#{arg} cmock_arg#{c+=1}"
        else
          arg
        end
      }.join(', ')
    end
  end

  def parse_declaration(declaration, namespace=[], classname=nil)
    decl = {}
    decl[:namespace] = namespace
    decl[:class] = classname

    regex_match = @declaration_parse_matcher.match(declaration)
    raise "Failed parsing function declaration: '#{declaration}'" if regex_match.nil?

    #grab argument list
    args = regex_match[2].strip

    #process function attributes, return type, and name
    parsed = parse_type_and_name(regex_match[1])

    decl[:name] = parsed[:name]
    decl[:modifier] = parsed[:modifier]
    unless parsed[:c_calling_convention].nil?
      decl[:c_calling_convention] = parsed[:c_calling_convention]
    end

    rettype = parsed[:type]
    rettype = 'void' if (@local_as_void.include?(rettype.strip))
    decl[:return] = { :type       => rettype,
                      :name       => 'cmock_to_return',
                      :str        => "#{rettype} cmock_to_return",
                      :void?      => (rettype == 'void'),
                      :ptr?       => parsed[:ptr?],
                      :const?     => parsed[:const?],
                      :const_ptr? => parsed[:const_ptr?]
                    }

    #remove default argument statements from mock definitions
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
    decl[:args_call] = decl[:args].map{|a| a[:name]}.join(', ')
    decl[:contains_ptr?] = decl[:args].inject(false) {|ptr, arg| arg[:ptr?] ? true : ptr }

    if (decl[:return][:type].nil?   or decl[:name].nil?   or decl[:args].nil? or
        decl[:return][:type].empty? or decl[:name].empty?)
      raise "Failed Parsing Declaration Prototype!\n" +
        "  declaration: '#{declaration}'\n" +
        "  modifier: '#{decl[:modifier]}'\n" +
        "  return: #{prototype_inspect_hash(decl[:return])}\n" +
        "  function: '#{decl[:name]}'\n" +
        "  args: #{prototype_inspect_array_of_hashes(decl[:args])}\n"
    end

    return decl
  end

  def prototype_inspect_hash(hash)
    pairs = []
    hash.each_pair { |name, value| pairs << ":#{name} => #{"'" if (value.class == String)}#{value}#{"'" if (value.class == String)}" }
    return "{#{pairs.join(', ')}}"
  end

  def prototype_inspect_array_of_hashes(array)
    hashes = []
    array.each { |hash| hashes << prototype_inspect_hash(hash) }
    case (array.size)
    when 0
      return "[]"
    when 1
      return "[#{hashes[0]}]"
    else
      return "[\n    #{hashes.join("\n    ")}\n  ]\n"
    end
  end

end
