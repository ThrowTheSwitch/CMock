# coding: utf-8
# ==========================================
#   CMock Project - Automatic Mock Generation for C
#   Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
#   [Released under MIT License. Please refer to license.txt for details]
# ==========================================

require "#{__dir__}/CLexer"

class CMockHeaderParser
  attr_accessor :funcs, :c_attr_noconst, :c_attributes, :treat_as_void, :treat_externs, :treat_inlines, :inline_function_patterns
  attr_reader :noreturn_attributes, :process_gcc_attributes, :process_cpp_attributes, :c_calling_conventions
  attr_reader :parse_project

  def initialize(cfg)
    @c_strippables = cfg.strippables
    @process_gcc_attributes = cfg.process_gcc_attributes
    @process_cpp_attributes = cfg.process_cpp_attributes
	@noreturn_attributes = cfg.noreturn_attributes.uniq
    @c_attr_noconst = cfg.attributes.uniq - ['const']
    @c_attributes = ['const'] + @c_attr_noconst
    @c_calling_conventions = cfg.c_calling_conventions.uniq
    @treat_as_array = cfg.treat_as_array
    @treat_as_void = (['void'] + cfg.treat_as_void).uniq
    attribute_regexp = '((?:\s*__attribute__\s*\(\s*\(.*?\)\s*\))*)'
    type_and_name_regexp = '([\w\s\*\(\),\[\]]*?\w[\w\s\*\(\),\[\]]*?)'
    args_regexp = '([\w\s\*\(\),\.\[\]+\-\/]*)'
    @function_declaration_parse_base_match = type_and_name_regexp+'\('+ args_regexp + '\)' + attribute_regexp
    @declaration_parse_matcher = /#{@function_declaration_parse_base_match}$/m
    @standards = (%w[int short char long unsigned signed] + cfg.treat_as.keys).uniq
    @array_size_name = cfg.array_size_name
    @array_size_type = (%w[int size_t] + cfg.array_size_type).uniq
    @when_no_prototypes = cfg.when_no_prototypes
    @local_as_void = @treat_as_void
    @verbosity = cfg.verbosity
    @treat_externs = cfg.treat_externs
    @treat_inlines = cfg.treat_inlines
    @inline_function_patterns = cfg.inline_function_patterns
    @c_strippables += ['extern'] if @treat_externs == :include # we'll need to remove the attribute if we're allowing externs
    @c_strippables += ['inline'] if @treat_inlines == :include # we'll need to remove the attribute if we're allowing inlines
    @c = 0
  end

  def raise_parse_error(message)
    # TODO: keep track of line number to be able to insert it in the error message.
    raise "#{@parse_project[:source_path]}:1: Failed Parsing Declaration Prototype!" + "\n" + message
  end

  def parse(src_path, name, source)
    $stderr.puts "Parsing #{src_path}" if @verbosity >= 1
    @parse_project = {
      :source_path       => src_path,
      :module_name       => name.gsub(/\W/, ''),
      :typedefs          => [],
      :functions         => [],
      :normalized_source => nil
    }

    function_names = []

    all_funcs = parse_functions(import_source(source)).map { |item| [item] }
    all_funcs += parse_cpp_functions(import_source(source, true))
    all_funcs.map do |decl|
      func = parse_declaration(*decl)
      unless function_names.include? func[:name]
        @parse_project[:functions] << func
        function_names << func[:name]
      end
    end

    @parse_project[:normalized_source] = if @treat_inlines == :include
                                          transform_inline_functions(source)
                                        else
                                          ''
                                        end

    { :includes  => nil,
      :functions => @parse_project[:functions],
      :typedefs  => @parse_project[:typedefs],
      :normalized_source    => @parse_project[:normalized_source] }
  end

  # REMVOVE BEFORE COMMIT #  private if $ThisIsOnlyATest.nil? ################

  # Remove C/C++ comments from a string
  # +source+:: String which will have the comments removed
  def remove_comments_from_source(source)
    # remove comments (block and line, in three steps to ensure correct precedence)
    source.gsub!(/(?<!\*)\/\/(?:.+\/\*|\*(?:$|[^\/])).*$/, '')  # remove line comments that comment out the start of blocks
    source.gsub!(/\/\*.*?\*\//m, '')                            # remove block comments
    source.gsub!(/\/\/.*$/, '')                                 # remove line comments (all that remain)
  end

  def remove_nested_pairs_of_braces(source)
    # remove nested pairs of braces because no function declarations will be inside of them (leave outer pair for function definition detection)
    if RUBY_VERSION.split('.')[0].to_i > 1
      # we assign a string first because (no joke) if Ruby 1.9.3 sees this line as a regex, it will crash.
      r = '\\{([^\\{\\}]*|\\g<0>)*\\}'
      source.gsub!(/#{r}/m, '{ }')
    else
      while source.gsub!(/\{[^\{\}]*\{[^\{\}]*\}[^\{\}]*\}/m, '{ }')
      end
    end

    source
  end

  # Return the number of pairs of braces/square brackets in the function provided by the user
  # +source+:: String containing the function to be processed
  def count_number_of_pairs_of_braces_in_function(source)
    is_function_start_found = false
    curr_level = 0
    total_pairs = 0

    source.each_char do |c|
      if c == '{'
        curr_level += 1
        total_pairs += 1
        is_function_start_found = true
      elsif c == '}'
        curr_level -= 1
      end

      break if is_function_start_found && curr_level == 0 # We reached the end of the inline function body
    end

    if curr_level != 0
      total_pairs = 0 # Something is fishy about this source, not enough closing braces?
    end

    total_pairs
  end

  # Transform inline functions to regular functions in the source by the user
  # +source+:: String containing the source to be processed
  def transform_inline_functions(source)
    inline_function_regex_formats = []
    square_bracket_pair_regex_format = /\{[^\{\}]*\}/ # Regex to match one whole block enclosed by two square brackets

    # Convert user provided string patterns to regex
    # Use word bounderies before and after the user regex to limit matching to actual word iso part of a word
    @inline_function_patterns.each do |user_format_string|
      user_regex = Regexp.new(user_format_string)
      word_boundary_before_user_regex = /\b/
      cleanup_spaces_after_user_regex = /[ ]*\b/
      inline_function_regex_formats << Regexp.new(word_boundary_before_user_regex.source + user_regex.source + cleanup_spaces_after_user_regex.source)
    end

    # let's clean up the encoding in case they've done anything weird with the characters we might find
    source = source.force_encoding('ISO-8859-1').encode('utf-8', :replace => nil)

    # Comments can contain words that will trigger the parser (static|inline|<user_defined_static_keyword>)
    remove_comments_from_source(source)

    # smush multiline macros into single line (checking for continuation character at end of line '\')
    # If the user uses a macro to declare an inline function,
    # smushing the macros makes it easier to recognize them as a macro and if required,
    # remove them later on in this function
    source.gsub!(/\s*\\(\n|\s*)/m, ' ')

    # Just looking for static|inline in the gsub is a bit too aggressive (functions that are named like this, ...), so we try to be a bit smarter
    # Instead, look for an inline pattern (f.e. "static inline") and parse it.
    # Below is a small explanation on how the general mechanism works:
    #  - Everything before the match should just be copied, we don't want
    #    to touch anything but the inline functions.
    #  - Remove the implementation of the inline function (this is enclosed
    #    in square brackets) and replace it with ";" to complete the
    #    transformation to normal/non-inline function.
    #    To ensure proper removal of the function body, we count the number of square-bracket pairs
    #    and remove the pairs one-by-one.
    #  - Copy everything after the inline function implementation and start the parsing of the next inline function
    # There are ofcourse some special cases (inline macro declarations, inline function declarations, ...) which are handled and explained below
    inline_function_regex_formats.each do |format|
      inspected_source = ''
      regex_matched = false
      loop do
        inline_function_match = source.match(/#{format}/) # Search for inline function declaration

        if inline_function_match.nil? # No inline functions so nothing to do
          # Join pre and post match stripped parts for the next inline function detection regex
          source = inspected_source + source if regex_matched == true
          break
        end

        regex_matched = true
        # 1. Determine if we are dealing with a user defined macro to declare inline functions
        # If the end of the pre-match string is a macro-declaration-like string,
        # we are dealing with a user defined macro to declare inline functions
        if /(#define\s*)\z/ =~ inline_function_match.pre_match
          # Remove the macro from the source
          stripped_pre_match = inline_function_match.pre_match.sub(/(#define\s*)\z/, '')
          stripped_post_match = inline_function_match.post_match.sub(/\A(.*[\n]?)/, '')
          inspected_source += stripped_pre_match
          source = stripped_post_match
          next
        end

        # 2. Determine if we are dealing with an inline function declaration iso function definition
        # If the start of the post-match string is a function-declaration-like string (something ending with semicolon after the function arguments),
        # we are dealing with a inline function declaration
        if /\A#{@function_declaration_parse_base_match}\s*;/m =~ inline_function_match.post_match
          # Only remove the inline part from the function declaration, leaving the function declaration won't do any harm
          inspected_source += inline_function_match.pre_match
          source = inline_function_match.post_match
          next
        end

        # 3. If we get here, we found an inline function declaration AND inline function body.
        # Remove the function body to transform it into a 'normal' function declaration.
        if /\A#{@function_declaration_parse_base_match}\s*\{/m =~ inline_function_match.post_match
          total_pairs_to_remove = count_number_of_pairs_of_braces_in_function(inline_function_match.post_match)

          break if total_pairs_to_remove == 0 # Bad source?

          inline_function_stripped = inline_function_match.post_match

          total_pairs_to_remove.times do
            inline_function_stripped.sub!(/\s*#{square_bracket_pair_regex_format}/, ';') # Remove inline implementation (+ some whitespace because it's prettier)
          end
          inspected_source += inline_function_match.pre_match
          source = inline_function_stripped
          next
        end

        # 4. If we get here, it means the regex match, but it is not related to the function (ex. static variable in header)
        # Leave this code as it is.
        inspected_source += inline_function_match.pre_match + inline_function_match[0]
        source = inline_function_match.post_match
      end
    end

    source
  end

  def import_source(source, cpp = false)
    # let's clean up the encoding in case they've done anything weird with the characters we might find
    source = source.force_encoding('ISO-8859-1').encode('utf-8', :replace => nil)

    # void must be void for cmock _ExpectAndReturn calls to process properly, not some weird typedef which equates to void
    # to a certain extent, this action assumes we're chewing on pre-processed header files, otherwise we'll most likely just get stuff from @treat_as_void
    @local_as_void = @treat_as_void
    void_types = source.scan(/typedef\s+(?:\(\s*)?void(?:\s*\))?\s+([\w]+)\s*;/)
    if void_types
      @local_as_void += void_types.flatten.uniq.compact
    end

    # If user wants to mock inline functions,
    # remove the (user specific) inline keywords before removing anything else to avoid missing an inline function
    if @treat_inlines == :include
      @inline_function_patterns.each do |user_format_string|
        source.gsub!(/#{user_format_string}/, '') # remove user defined inline function patterns
      end
    end

    # smush multiline macros into single line (checking for continuation character at end of line '\')
    source.gsub!(/\s*\\\s*/m, ' ')

    remove_comments_from_source(source)

    # remove assembler pragma sections
    source.gsub!(/^\s*#\s*pragma\s+asm\s+.*?#\s*pragma\s+endasm/m, '')

    if @noreturn_attributes.nil?
      # remove gcc's __attribute__ tags
      source.gsub!(/__attribute(?:__)?\s*\(\(+.*\)\)+/, '')
    end

    # remove preprocessor statements and extern "C"
    source.gsub!(/extern\s+\"C\"\s*\{/, '')
    source.gsub!(/^\s*#.*/, '')

    # enums, unions, structs, and typedefs can all contain things (e.g. function pointers) that parse like function prototypes, so yank them
    # forward declared structs are removed before struct definitions so they don't mess up real thing later. we leave structs keywords in function prototypes
    source.gsub!(/^[\w\s]*struct[^;\{\}\(\)]+;/m, '')                                      # remove forward declared structs
    source.gsub!(/^[\w\s]*(enum|union|struct|typedef)[\w\s]*\{[^\}]+\}[\w\s\*\,]*;/m, '')  # remove struct, union, and enum definitions and typedefs with braces
    # remove problem keywords
    source.gsub!(/(\W)(?:register|auto|restrict)(\W)/, '\1\2')
    source.gsub!(/(\W)(?:static)(\W)/, '\1\2') unless cpp

    source.gsub!(/\s*=\s*['"a-zA-Z0-9_\.]+\s*/, '')                                        # remove default value statements from argument lists
    source.gsub!(/^(?:[\w\s]*\W)?typedef\W[^;]*/m, '')                                     # remove typedef statements
    source.gsub!(/\)(\w)/, ') \1')                                                         # add space between parenthese and alphanumeric
    source.gsub!(/(^|\W+)(?:#{@c_strippables.join('|')})(?=$|\W+)/, '\1') unless @c_strippables.empty? # remove known attributes slated to be stripped

    # scan standalone function pointers and remove them, because they can just be ignored
    source.gsub!(/\w+\s*\(\s*\*\s*\w+\s*\)\s*\([^)]*\)\s*;/, ';')

    # scan for functions which return function pointers, because they are a pain
    source.gsub!(/([\w\s\*]+)\(*\(\s*\*([\w\s\*]+)\s*\(([\w\s\*,]*)\)\)\s*\(([\w\s\*,]*)\)\)*/) do |_m|
      functype = "cmock_#{parse_project[:module_name]}_func_ptr#{parse_project[:typedefs].size + 1}"
      unless cpp # only collect once
        parse_project[:typedefs] << "typedef #{Regexp.last_match(1).strip}(*#{functype})(#{Regexp.last_match(4)});"
        "#{functype} #{Regexp.last_match(2).strip}(#{Regexp.last_match(3)});"
      end
    end

    source = remove_nested_pairs_of_braces(source) unless cpp

    if @treat_inlines == :include
      # Functions having "{ }" at this point are/were inline functions,
      # User wants them in so 'disguise' them as normal functions with the ";"
      source.gsub!('{ }', ';')
    end

    # remove function definitions by stripping off the arguments right now
    source.gsub!(/\([^\)]*\)\s*\{[^\}]*\}/m, ';')

    # drop extra white space to make the rest go faster
    source.gsub!(/^\s+/, '')          # remove extra white space from beginning of line
    source.gsub!(/\s+$/, '')          # remove extra white space from end of line
    source.gsub!(/\s*\(\s*/, '(')     # remove extra white space from before left parens
    source.gsub!(/\s*\)\s*/, ')')     # remove extra white space from before right parens
    source.gsub!(/\s+/, ' ')          # remove remaining extra white space

    # split lines on semicolons and remove things that are obviously not what we are looking for
    src_lines = source.split(/\s*;\s*/)
    src_lines = src_lines.uniq unless cpp # must retain closing braces for class/namespace
    src_lines.delete_if { |line| line.strip.empty? } # remove blank lines
    src_lines.delete_if { |line| !(line =~ /[\w\s\*]+\(+\s*\*[\*\s]*[\w\s]+(?:\[[\w\s]*\]\s*)+\)+\s*\((?:[\w\s\*]*,?)*\s*\)/).nil? } # remove function pointer arrays

    unless @treat_externs == :include
      src_lines.delete_if { |line| !(line =~ /(?:^|\s+)(?:extern)\s+/).nil? } # remove extern functions
    end

    unless @treat_inlines == :include
      src_lines.delete_if { |line| !(line =~ /(?:^|\s+)(?:inline)\s+/).nil? } # remove inline functions
    end

    src_lines.delete_if(&:empty?) # drop empty lines
	src_lines
  end

  # Rudimentary C++ parser - does not handle all situations - e.g.:
  #  * A namespace function appears after a class with private members (should be parsed)
  #  * Anonymous namespace (shouldn't parse anything - no matter how nested - within it)
  #  * A class nested within another class
  def parse_cpp_functions(source)
    funcs = []

    ns = []
    pub = false
    source.each do |line|
      # Search for namespace, class, opening and closing braces
      line.scan(/(?:(?:\b(?:namespace|class)\s+(?:\S+)\s*)?{)|}/).each do |item|
        if item == '}'
          ns.pop
        else
          token = item.strip.sub(/\s+/, ' ')
          ns << token

          pub = false if token.start_with? 'class'
          pub = true if token.start_with? 'namespace'
        end
      end

      pub = true if line =~ /public:/
      pub = false if line =~ /private:/ || line =~ /protected:/

      # ignore non-public and non-static
      next unless pub
      next unless line =~ /\bstatic\b/

      line.sub!(/^.*static/, '')
      next unless line =~ @declaration_parse_matcher

      tmp = ns.reject { |item| item == '{' }

      # Identify class name, if any
      cls = nil
      if tmp[-1].start_with? 'class '
        cls = tmp.pop.sub(/class (\S+) {/, '\1')
      end

      # Assemble list of namespaces
      tmp.each { |item| item.sub!(/(?:namespace|class) (\S+) {/, '\1') }

      funcs << [line.strip.gsub(/\s+/, ' '), tmp, cls]
    end
    funcs
  end

  def parse_functions(source)
    funcs = []
    source.each { |line| funcs << line.strip.gsub(/\s+/, ' ') if line =~ @declaration_parse_matcher }
    if funcs.empty?
      case @when_no_prototypes
      when :error
        raise 'ERROR: No function prototypes found!'
      when :warn
        puts 'WARNING: No function prototypes found!' unless @verbosity < 1
      end
    end
    funcs
  end

  # This grammar is quite ambiguous:
  #
  # fun_declaration : type name parameters { attributes | c_calling_convention } ;
  #
  # type : stuffs ;
  #
  # stuffs : | stuff stuffs ;
  # 
  # stuff : token
  #       | :open_paren stuffs :close_paren
  #       | :open_bracket stuffs :close_bracket
  #       | :open_brace stuffs :close_brace
  #       | :lt stuffs :gt' -- angle brackets
  #       ;
  # -- Note: we will also scan char_literal and string_literal 
  # --       because they could appear in constant expressions (eg. enums) 
  # --       and contain parentheses.
  # -- Note: angle brackets for templates are very ambiguous, because
  # --       we may also have '<' tokens in constant expressions (eg. in a enum).
  # --       So we'd need a real parser to handle this correctly.
  #
  # token : identifier | literals_and_other_tokens ;
  #
  # name : identifier ;
  #
  # parameters : :open_paren stuffs :close_paren ;
  #
  # attributes : '__attributes__'  :open_paren stuffs :close_paren ;
  # -- we won't parse macro calls in attributes because of the ambiguity.
  #
  #
  # Therefore we will parse in two phases:
  # Phase 1: 
  #     we parse fun_declaration_1 : { stuff } ;
  #     -- this takes care of parentheses, et al.
  # Phase 2:
  #    then match from the end of the list of stuffs,
  #    for c_calling_conventions, __attributes__ (...)
  #    then '(' parameters ')' = '(' stuffs ')'
  #    then name identifier,
  #    then the rest is type.

  def eos?(src,pos)
    src.length<=pos
  end

  def validate_identifier(token,what) 
    if token[0] == :identifier
      token
    else
      raise_parse_error "Expected #{what} identifier, got #{token[0]} #{token[1]}"
    end
  end

  def parse_token(src,pos)
    if eos?(src,pos)
      raise_parse_error "Expected a token, not end of source at position #{pos}"
    end
    [ src[pos], pos+1 ]
  end

  def parse_stuff(src,pos)
    # stuff : token
    #       | '(' stuffs ')' 
    #       | '[' stuffs ']' 
    #       | '{' stuffs '}'
    #       | '<' stuffs '>' 
    #       ;
    stuff = nil
    if not eos?(src,pos)
      case src[pos]
      when :open_paren   then stuff, pos = parse_delimited_stuffs(src, pos, :close_paren)
      when :open_bracket then stuff, pos = parse_delimited_stuffs(src, pos, :close_bracket)
      when :open_brace   then stuff, pos = parse_delimited_stuffs(src, pos, :close_brace)
      when :lt           then stuff, pos = parse_delimited_stuffs(src, pos, :gt)
      else stuff, pos = parse_token(src, pos)
      end
    end
    [stuff, pos]
  end

  def parse_delimited_stuffs(src,pos,closing)
    pos += 1 # eat the opening tokenn
    stuffs = []
    while not eos?(src, pos) and src[pos] != closing
      item, pos = parse_stuff(src, pos)
      stuffs << item
    end
    if not eos?(src, pos)
      pos += 1 # skip closing token
    end
    op = case closing
         when :close_paren   then :parens
         when :close_bracket then :brackets
         when :close_brace   then :braces
         when :gt            then :angle_brackets
         end
    [ [op, stuffs], pos ]
  end

  def parse_stuffs(src,pos)
    # stuffs : | stuff stuffs ;
    stuffs = []
    while not eos?(src, pos)
      stuff, pos = parse_stuff(src, pos)
      stuffs << stuff unless stuff.nil?
    end
    [ stuffs, pos ]
  end

  def is_parens(stuff)
	stuff.is_a?(Array) and (stuff.length == 2) and (stuff[0] == :parens)
  end

  def parens_list(stuff)
    stuff[1] if is_parens(stuff)
  end

  def is_brackets(stuff)
	stuff.is_a?(Array) and (stuff.length == 2) and (stuff[0] == :brackets)
  end

  def brackets_list(stuff)
    stuff[1] if is_brackets(stuff)
  end

  def is_token(token)
    token.is_a?(Symbol) and (CLexer::OPERATOR_SYMS.index(token) or CLexer::KEYWORDS_SYMS.index(token))
  end

  def is_identifier(token,name=nil)
    if token.is_a?(Array) and (token.length == 2)
      if name.nil?
        (token[0] == :identifier)
      else
        (token[0] == :identifier) and (token[1] == name)
      end
    else
      false
    end
  end

  def identifier_name(token)
    token[1] if token.is_a?(Array) and (token[0] == :identifier)
  end

  def token_name(token)
    if is_identifier(token)
      identifier_name(token)
    elsif token.is_a?(Symbol)
      token.to_s
    elsif token.is_a?(String)
      token
    else
      raise_parse_error "Invalid token #{token.inspect}"
    end
  end

  def is_c_calling_convention(stuff)
    # whether stuff is a C calling convention (listed in @c_calling_conventions).
    # note: stuff may be either a symbol, a string or an :identifier array.
    res = if stuff.is_a?(Symbol) or is_token(stuff) or is_identifier(stuff)
            not @c_calling_conventions.index(token_name(stuff)).nil?
          else
            false
          end
    res
  end

  def is_c_attribute(token)
    # whether the token is a C attribute (listed in @c_attributes or in @noreturn_attributes).
    # note: token may be either a symbol, a string or an :identifier array.
    if token.is_a?(String)
      name = token
    elsif token.is_a?(Symbol)
      name = token.to_s
    elsif is_token(token) or is_identifier(token)
      name = token_name(token)
    elsif is_attribute(token)
      name = attribute_name(token)
    else 
      return false
    end

    res = (@c_attributes.index(name) or
           ((not @noreturn_attributes.nil?) and
            (@noreturn_attributes.any? { |attr_regexp| name =~ /^#{attr_regexp}$/ })))
    res
  end

  def make_attribute(namespace,name,arguments,kind)
    if name.nil?
      raise_parse_error "Attribute name should not be nil! #{namespace.inspect}, #{name.inspect}, #{arguments.inspect}" 
    end
    [:attribute,namespace,name,arguments,kind]
  end

  def is_attribute(object)
    (object.is_a?(Array)) and (object.length == 5) and (object[0] == :attribute)
  end

  def attribute_namespace(attribute)
    raise_parse_error "Not an normalized attribute: #{attribute}" unless is_attribute(attribute)
    attribute[1]
  end

  def attribute_name(attribute)
    raise_parse_error "Not an normalized attribute: #{attribute}" unless is_attribute(attribute)
    attribute[2]
  end

  def attribute_qualified_name(attribute)
    if attribute_namespace(attribute)
      attribute_namespace(attribute) + "::" + attribute_name(attribute)
    else
      attribute_name(attribute)
    end
  end

  def attribute_arguments(attribute)
    raise_parse_error "Not an normalized attribute: #{attribute}" unless is_attribute(attribute)
    attribute[3]
  end

  def attribute_kind(attribute)
    raise_parse_error "Not an normalized attribute: #{attribute}" unless is_attribute(attribute)
    attribute[4]
  end

  def is_noreturn(attribute)
    if is_identifier(attribute)
      @noreturn_attributes.include?(identifier_name(attribute))
    elsif is_attribute(attribute)
      @noreturn_attributes.include?(attribute_qualified_name(attribute))
    else
      false
    end
  end

  def has_noreturn_attribute(attributes)
    attributes.any? do |attribute|
      is_noreturn(attribute)
    end
  end

  def is_gcc_attribute_syntax(operator, parameters)
    # gcc atributes are all of the syntax  __attribute__ (...)
    # where ... is a list of stuffs.
    # so is_gcc_attribute_syntax([:identifier,"__attribute__"],[:parens,stuff_list])
    is_identifier(operator,'__attribute__') and is_parens(parameters) 
    # see parse_gcc_attribute
  end

  def is_processable_gcc_attribute(name)
    is_c_attribute(name)
  end

  def parse_gcc_attribute(op,stuff)
    # gcc atributes are all of the syntax  __attribute__ (...)
    # where ... is a list of stuffs.
    # Here, attribute = [:attribute, [:parens,stuff_list]]
    # We want to normalize attribute into a list of atributes:
    #
    # [:attribute,[:parens,[[:parens,[:identifier,"foo"],:comma,[:identifier,"bar"]]]]]
    # --> [[:attribute,[:identifier,"foo"],[:parens,[[:identifier,"bar"]])]]]
    #
    # [:attribute,[:parens,[[:parens,[[:identifier,"foo"]]],:comma,[:parens,[[:identifier,"bar"]]]]]]
    # --> [[:attribute,[:identifier "foo"]],nil],[[:attribute,[:identifier,"bar"]],nil]]
    #
    # [:attribute, [:parens,[[:parens,
    #                         [[:identifier,"access"],[:parens,[[:identifier,"read_write"],:comma,[:integer_literal,"1"]]],:comma,
    #                          [:identifier,"access"],[:parens,[[:identifier,"read_only"],:comma,[:integer_literal,"2"]]]]]]]]]
    #
    # --> [[:attribute,[:identifier,"access"],[:parens,[[:identifier,"read_write"],[:integer_literal,"1"]]]],
    #      [:attribute,[:identifier,"access"],[:parens,[[:identifier,"read_only"],[:integer_literal,"2"]]]]]

    if not (is_identifier(op,'__attribute__') and is_parens(stuff) and is_parens(parens_list(stuff)[0]))
      raise_parse_error "Unexpected attribute syntax #{[op,stuff].inspect}" 
    end
    normalized = []
    j=0
    chunks = parens_list(stuff)
    while j<chunks.length
      chunk = chunks[j]
      j += 1
      if chunk != :comma
        items = parens_list(chunk)
        i=0
        name = nil
        while i<items.length
          thing = items[i]
          i += 1
          if name.nil?
            if thing == :comma
            # wait for next
            elsif is_identifier(thing) 
              name = thing
            elsif thing.is_a?(Symbol)
              name = thing
            else
              raise_parse_error "Unexpected attribute syntax #{attribute.inspect}"
            end
          else
            if thing == :comma
              if is_processable_gcc_attribute(token_name(name))
                normalized << make_attribute(nil,token_name(name),nil,:gcc)
              end
              name = nil
            elsif is_parens(thing)
              if is_processable_gcc_attribute(token_name(name))
                normalized << make_attribute(nil,token_name(name),thing,:gcc)
              end
              name = nil
              if i < items.length and items[i] = :comma
                i += 1
              end
            else
              raise_parse_error "Unexpected attribute syntax #{attribute.inspect}"
            end
          end
        end
        if not name.nil?
          if is_processable_gcc_attribute(token_name(name))
            normalized << make_attribute(nil,token_name(name),nil,:gcc)
          end
          name = nil
        end
      end
    end
    normalized
  end

  def is_cpp_attribute_syntax(stuff)
    is_brackets(stuff) and (brackets_list(stuff).length == 1) and 
      is_brackets(brackets_list(stuff)[0])
  end

  def is_processable_cpp_attribute(name)
    is_c_attribute(name)
  end

  def parse_cpp_attributes(stuff)
    # stuff = '[[' [ 'using' <namespace_identifier> ':' ] <attribute> { ',' <attribute> } ']]' ;
    # attribute = [ <namespace_identifier> '::' ] <identifier> [ '(' <argument_list> ')' ] ;
    attributes = []

    if not (is_brackets(stuff) and (1 == brackets_list(stuff).length) and is_brackets(brackets_list(stuff)[0]))
      raise_parse_error "Unexpected C++ attribute syntax #{stuff.inspect}" +
                        "\nis_brackets(stuff) = #{is_brackets(stuff)}" +
                        "\nbrackets_list(stuff).length = #{is_brackets(stuff) ? brackets_list(stuff).length : nil}" +
                        "\nis_brackets(brackets_list(stuff)[0]) = #{is_brackets(stuff) and brackets_list(stuff).length>1 ? is_brackets(brackets_list(stuff)[0]) : nil}"
    end
    
    stuff = brackets_list(brackets_list(stuff)[0])

    # Note: for better support for C++, we'd have to update CLexer for C++ tokens.
    # so using would be :using, and :: would be :double-colon insead of :colon :colon
    # etc (but C++ lexers must be context-sensitive).

    default_namespace = nil
    start=0
    if 3<stuff.length and (is_identifier(stuff[0]) or is_token(stuff[0])) and token_name(stuff[0]) == "using"
      if is_identifier(stuff[1]) and :colon == stuff[2]
        default_namespace = identifier_name(stuff[1])
        start = 3
      else
        raise_parse_error "Invalid using syntax in attributes #{stuff.inspect}"
      end
    end

    i = start
    while i<stuff.length
      namespace = default_namespace
      name = nil
      arguments = nil

      if is_identifier(stuff[i]) 
        if (i+2<stuff.length) and (:colon == stuff[i+1]) and (:colon == stuff[i+2])
          namespace = identifier_name(stuff[i])
          i += 3
        end
      end
      if i<stuff.length and is_identifier(stuff[i]) 
        name = identifier_name(stuff[i])
        i += 1
        if i<stuff.length and is_parens(stuff[i]) 
          # we don't further parse the arguments, this may be done lazily if needed.
          arguments = stuff[i] 
          i += 1
        end
        if is_processable_cpp_attribute((namespace ? namespace+'::' : '' )+name)
          attributes << make_attribute(namespace,name,arguments,:cpp)
        end
        if i<stuff.length and :comma == stuff[i]
          i += 1
        end
      elsif i<stuff.length
        raise_parse_error "Unexpected token #{stuff[i].inspect} in C++11 attribute expression #{stuff.inspect}, expected an attribute identifier."
      end
    end
    attributes
  end


  def guess_ptr_and_const(type)
    # type is a stuffs list
    guess = {}
    starc = type.count(:mul_op)
    first_const = type.index(:const)
    last_const = type.rindex(:const)
    char = type.index(:char)
    last_star = type.rindex(:mul_op)

    if char.nil?
      guess[:ptr?] = starc>0
    else
      # char* are "strings", not "pointers".
      guess[:ptr?] = starc>1
    end

    if first_const.nil?
      # no const:
      guess[:const?] = false
    elsif starc == 0
	  # const, no star
      guess[:const?] = true
    else
      # const, some star:
      before_last_star = type[0..last_star-1].rindex(:mul_op)
      
      if before_last_star.nil?
		# a single star: 
        guess[:const?] = (first_const<last_star)
      else
        const = type[before_last_star..last_star].index(:const)
        guess[:const?] = not(const.nil?)
      end
    end

    # an arg containing "const" after the last * is a constant pointer
    guess[:const_ptr?] = ((starc>0) and (not last_const.nil?) and (last_star < last_const))

    guess
  end

  def parse_function_signature(src,pos)

    # Phase 1: 
    #     we parse fun_declaration_1 : { stuff } ;
    #     -- this takes care of parentheses, et al.
    items, pos = parse_stuffs(src, pos)
    raise_parse_error "Unparsed characters from position #{pos}" unless  pos == src.length

    # Phase 2:
    #    then match from the end of the list of stuffs,
    #    for c_calling_conventions, __attributes__ (...)
    #    then '(' parameters ')' = '(' stuffs ')'
    #    then name identifier,
    #    then the rest is type.

    ccc = []
    attributes = []
    parameters = nil

    # match from the end of the list of stuffs,
    #    for c_calling_conventions, __attributes__ (...)
    i = items.length-1
    while is_c_calling_convention(items[i]) or ((3<=i) and is_gcc_attribute_syntax(items[i-1],items[i]))
      if is_c_calling_convention(items[i])
        ccc << [:c_calling_convention, token_name(items[i])]
        i -= 1
      else
        attributes += parse_gcc_attribute(items[i-1],items[i])
        i -= 2
      end
    end

    #    then '(' parameters ')' = '(' stuffs ')'
    if is_parens(items[i])
      parameters = parens_list(items[i])
      i -= 1
    end

    #    then name identifier,
    if not is_identifier(items[i])
      raise_parse_error "Expected an identifier but got #{items[i].inspect} as function name in #{items.inspect}"
    end
    name = identifier_name(items[i])
    i -= 1

    #    then the rest is type.
    type = items[0..i]

    [type, name, parameters, attributes, ccc]
  end

  def parse_type(stuff)
    # Split up words and remove known attributes.  For pointer types, make sure
    # to remove 'const' only when it applies to the pointer itself, not when it
    # applies to the type pointed to.  For non-pointer types, remove any
    # occurrence of 'const'.

    arg_info = guess_ptr_and_const(stuff)

    @attributes = (stuff.any?{|item| item == :mul_op}) ? @c_attr_noconst : @c_attributes

    type = []
    attributes = []
    ccc = []
    i = 0
    while i<stuff.length
      if (i+1<stuff.length) and is_gcc_attribute_syntax(stuff[i], stuff[i+1]) # __attribute__ ( ... )
        if @process_gcc_attributes
          attributes += parse_gcc_attribute(stuff[i],stuff[i+1])
        end
        i += 1
      elsif is_cpp_attribute_syntax(stuff[i]) # [[ ... ]]
        if @process_cpp_attributes
          attributes += parse_cpp_attributes(stuff[i])
        end
      elsif is_c_attribute(stuff[i])
        attributes << make_attribute(nil,token_name(stuff[i]),nil,:c)
      elsif is_c_calling_convention(stuff[i])
        ccc << [:c_calling_convention, token_name(stuff[i])]
      else
        type << stuff[i]
      end
      i += 1
    end

    if arg_info[:const_ptr?]
      attributes << make_attribute(nil,'const',nil,:c)
      cindex = type.rindex(:const)
      type.delete_at(cindex) unless cindex.nil?
    end

    arg_info[:type] = unparse(type).gsub(/\s+\*/, '*') # remove space before asterisks
    arg_info[:modifier] = unparse(attributes.uniq)
    arg_info[:c_calling_convention] = unparse(ccc)

    [type, attributes, ccc, arg_info]
  end

  def unparse_inner(stuff)
    if CLexer::OPERATOR_SYMS.include?(stuff)
      CLexer::OPERATOR_SYMBOLS.key(stuff)
    elsif CLexer::KEYWORDS_SYMS.include?(stuff)
      stuff.to_s
    elsif stuff.nil?
      ""
    elsif stuff.is_a?(Array)
      case stuff[0]
      when :identifier, :string_literal, :char_literal,
           :integer_literal, :float_literal, :hex_literal then stuff[1]
      when :c_calling_convention then "#{unparse_inner(stuff[1])}"
      when :parens then "(#{unparse_inner(stuff[1])})"
      when :brackets then "[#{unparse_inner(stuff[1])}]"
      when :braces then "{#{unparse_inner(stuff[1])}}"
      when :angle_brackets then "<#{unparse_inner(stuff[1])}>"
      when :attribute then
        case attribute_kind(stuff)
        when :gcc then "__attribute__((#{unparse_inner(attribute_qualified_name(stuff))}))"
        when :cpp then "[[#{unparse_inner(attribute_qualified_name(stuff))}]]"
        when :c then "#{unparse_inner(attribute_qualified_name(stuff))}"
        end
      else stuff.map{|item| unparse_inner(item)}.join(' ')
      end
    elsif stuff.is_a?(String)
      stuff
    else
      raise_parse_error "Unexpected stuff #{stuff.inspect} while unparsing #{@unparsing.inspect}"
    end
  end

  def unparse(stuff)
    @unparsing = stuff
    unparse_inner(stuff)
  end

  
  def replace_arrays_by_pointers_in_parameters(parameters)
    # parameter is now a list of parameter declarations each being a lists of tokens.
    #
    # eg. for (int* b, int c[5], int (*(*farr)[4])(int x),int a=42) we'd have now (=42 has been removed earlier):
    #
    #     [ [ :int, :mul_op, [:identifier, "b"] ],
    #       [ :int, [:identifier, "c"], [:brackets, [[:integer_literal, "5"]]] ],
    #       [ :int, [:parens, [:mul_op, [:parens, [:mul_op, [:identifier, "farr"]]],
    #                                   [:brackets, [[:integer_literal, "4"]]]]],
    #               [:parens, [:int, [:identifier, "x"]]]] ],
    #       [ :int, [:identifier, "a"] ] ]

    # we want to turn instances of:  [..., stuff, [:brackets, ... ], ...]  into: [..., :mul_op, stuff]
    # Note: a single pointer for multidimensionnal arrays: 
    #   foo_t  foo[][][] --> foo_t* foo
    #   foo_t* foo[][][] --> foo_t** foo
    if parameters == [[]]
      parameters
    else
      parameters.map do |parameter|
        if is_parens(parameter) 
	      [:parens] + replace_arrays_by_pointers_in_parameters([parens_list(parameter)])
        elsif parameter.is_a?(Array) 
	      i = parameter.rindex{|item| not is_brackets(item)}
          if i.nil? then
	        # all items are brackets
            raise_parse_error "All items are brackets parameter=#{parameter.inspect}"
          elsif i == parameter.length-1 then
            # no item is a brackets
		    parameter
          else
	        # some brackets, remove them and insert * before the name
		    # Note: int foo[3][4][5] --> int* foo
		    parameter[0,i] + [:mul_op] + [parameter[i]]
          end.map do |item|
            # recurse into parens groups:
            if is_parens(item) 
              [:parens] + replace_arrays_by_pointers_in_parameters([parens_list(item)])
            else 
              item 
            end
          end
        else
          parameter
        end
      end
    end
  end

#   replace_arrays_by_pointers_in_parameters([ [ :int, :mul_op, [:identifier, "b"] ],
#                                              [ :int, [:identifier, "c"], [:brackets, [[:integer_literal, "5"]]] ],
#                                              [ :int, [:parens, [:mul_op, [:parens, [:mul_op, [:identifier, "farr"]]],
#                                                                          [:brackets, [[:integer_literal, "4"]]]]],
#                                                      [:parens, [:int, [:identifier, "x"]]] ],
#                                              [ :int, [:identifier, "a"] ] ])
# ==> 
# [[:int, :mul_op, [:identifier, "b"]],
#  [:int, :mul_op, [:identifier, "c"]],
#  [:int,
#   [:parens, [:mul_op, :mul_op, [:parens, [:mul_op, [:identifier, "farr"]]]]],
#   [:parens, [:int, [:identifier, "x"]]]],
#  [:int, [:identifier, "a"]]]


  def replace_function_pointers_by_custom_types(parameters)
    parameters.map do |parameter|
      plen = parameter.length
      if 2<plen and is_parens(parameter[-1]) # ...x()
        if is_parens(parameter[-2]) # ...()()

          spec = parens_list(parameter[-2])
          ptrindex = spec.index(:mul_op)
          if ptrindex # ...(...*...)()

            funcdecl = (ptrindex>0) ? spec[0..ptrindex-1] : []
            funcname = spec[ptrindex+1..-1]
            constindex = funcname.index(:const)
            if constindex
              funcname.delete_at(constindex)
              funcconst = [:const]
            else
              funcconst = []
            end

          else
            raise_parse_error "Invalid syntax for function parameter #{parameter.inspect}"
          end

        elsif is_identifier(parameter[-2])  # ...foo()

          funcdecl = []
          funcname = [parameter[-2]]
          funcconst = []

        else
          raise_parse_error "Invalid syntax for function parameter #{parameter.inspect}"
        end

        functype = [:identifier,"cmock_#{@parse_project[:module_name]}_func_ptr#{@parse_project[:typedefs].size + 1}"]
        funcret = parameter[0..-3]
        funcargs = parameter[-1]

        # add typedef for function pointer
        @parse_project[:typedefs] << "typedef #{unparse(funcret)}(#{unparse(funcdecl+[:mul_op]+[functype])})#{unparse(funcargs)};".gsub(/\(\*\s+/,'(*').gsub(/\s+\*/,'*').gsub(/\s+,/,',')
        funcname = [[:identifier, "cmock_arg#{@c += 1}"]] if funcname.empty?
        [functype] + funcconst + funcname
      else
        parameter
      end
    end
  end

  def is_anonymous_parameter(parameter)
    parameter = parameter.reject { |token| [:struct, :union, :enum, :const, :mul_op].include?(token) }
    if (parameter.length == 0)
      true
    elsif (parameter.length == 1)
      not (parameter[0] == :ellipsis)
    else
      not is_identifier(parameter[-1])
    end
  end

  def add_names_to_anonymous_parameters(parameters)
    parameters.map do |parameter|
      if parameter.nil?
        nil
      elsif is_anonymous_parameter(parameter)
        parameter << [:identifier, "cmock_arg#{@c += 1}"]
      else
        parameter
      end
    end
  end

  def parameter_unwrap_superfluous_parentheses(parameter)
    pc = parameter.count { |item| is_parens(item) } 
    if (pc == 1) and is_parens(parameter[-1]) and 
      (parens_list(parameter[-1]).length == 1) and
      is_parens(parens_list(parameter[-1])[0])
      # ... ((...)) --> unwrap ... (...) 
      parameter_unwrap_superfluous_parentheses(parameter[0..-2] + parens_list(parameter[-1]))
    elsif (pc == 1) and is_parens(parameter[-1]) and 
         (parens_list(parameter[-1]).length == 2) and
         is_parens(parens_list(parameter[-1])[0]) and
         is_parens(parens_list(parameter[-1])[1])
      # ... ((...)(...)) --> unwrap ... (...)(...)
      parameter_unwrap_superfluous_parentheses(parameter[0..-2] +
                                               [parens_list(parameter[-1])[0]] +
                                               [parens_list(parameter[-1])[1]])
    elsif (pc == 2) and is_parens(parameter[-2]) and is_parens(parameter[-1]) and
         (parens_list(parameter[-2]).length == 1) and
         is_parens(parens_list(parameter[-2])[0])         
      # ... ((...)) (...) --> unwrap ... (...) (...)
      parameter_unwrap_superfluous_parentheses(parameter[0..-3] + parens_list(parameter[-2]) + parameter[-1])
    else
      parameter
    end
  end

  def clean_args(parameters)
    # parameter is now a list of parameter declarations each being a lists of tokens.
    # eg. for (int* b, int c[5], int a=42) we'd have now (=42 has been removed earlier):
    #     [ [ :int, :mul_op, [:identifier, "b"] ],
    #       [ :int, [:identifier, "c"], [:brackets, [:integer_literal, "5"]] ],
    #       [ :int, [:identifier, "a"] ] ]

    if parameters.empty? or ((parameters.length == 1) and @local_as_void.include?(unparse(parameters[0])))
      [:void]
    else
      @c = 0

      # unwrap superfluous parentheses, eg.:
      #
      # [:int, [:parens, [[:parens, [[:identity, "foo"],[:parens,[[:int,:comma,:int]]]]]]]]
      # --> [:int, [:identity, "foo"], [:parens,[[:int,:comma,:int]]]]
      #
      # [:int, [:parens, [[:parens, [[:parens, [[:mul_op,[:identity, "foo"]]]], [:parens,[[:int,:comma,:int]]]]]]]]
      # --> [:int, [:parens, [[:mul_op,[:identity, "foo"]]]], [:parens,[[:int,:comma,:int]]]]

      parameters = parameters.map { |parameter| parameter_unwrap_superfluous_parentheses(parameter) }

      # magically turn brackets into asterisks, also match for parentheses that come from macros
      parameters = replace_arrays_by_pointers_in_parameters(parameters)

      # scan argument list for function pointers and replace them with custom types 
      # scan argument list for function pointers with shorthand notation and replace them with custom types
      # Note: if I'm not wrong, this new code using tokens handles both cases, with and without funcdecl.
      # parameters=[[:unsigned, :int, [:parens, [:mul_op, [:identifier, "func_ptr"]]], [:parens, [:int, :comma, :char]]]]
      parameters=replace_function_pointers_by_custom_types(parameters)

      # automatically name unnamed arguments (those that only had a type)
      parameters = add_names_to_anonymous_parameters(parameters)

      if parameters.any?(nil)
        raise_parse_error "Invalid parameters #{parameters.inspect}"
      end
      parameters
    end
  end

  def is_string_type(type)
    (type.length>=2) and (type[0]==:char) and (type[1]==:mul_op)
  end

  def parse_args(parameters)
    # parameters have been cleaned (clean_args)
    # so they're each of the form :void, :ellipsis, or [type... name]
    args = []
    parameters.each do |parameter|
      return args if (parameter == :void) or (parameter == [:ellipsis])

      if parameter.nil? or (parameter.length<2)
        raise_parse_error "Invalid parameter #{parameter.inspect} in #{parameters.inspect}"
      else
        type=parameter[0..-2]
        name=parameter[-1]
        type, _, _, arg_info = parse_type(type)
        arg_info[:name]=identifier_name(name)
        arg_info.delete(:modifier)             # don't care about this
        arg_info.delete(:noreturn)             # don't care about this
        arg_info.delete(:c_calling_convention) # don't care about this

        # in C, array arguments implicitly degrade to pointers
        # make the translation explicit here to simplify later logic
        if @treat_as_array[arg_info[:type]] && !(arg_info[:ptr?])
          arg_info[:type] = "#{@treat_as_array[arg_info[:type]]}*"
          arg_info[:ptr?] = true
          arg_info[:type] = "const #{arg_info[:type]}" if arg_info[:const?]
        elsif arg_info[:ptr?] or is_string_type(type)
          if arg_info[:const?] 
            arg_info[:type] = "const #{arg_info[:type]}"
          end
        end

        args << arg_info
      end
    end

    # Try to find array pair in parameters following this pattern : <type> * <name>, <@array_size_type> <@array_size_name>
    args.each_with_index do |val, index|
      next_index = index + 1
      next unless args.length > next_index

      if (val[:ptr?] == true) && args[next_index][:name].match(@array_size_name) && @array_size_type.include?(args[next_index][:type])
        val[:array_data?] = true
        args[next_index][:array_size?] = true
      end
    end

    args
  end
  
  def parse_declaration(declaration, namespace = [], classname = nil)
    decl = {}
    decl[:namespace] = namespace
    decl[:class] = classname

    lexer = CLexer.new(declaration)
    decl_tokens = lexer.tokenize

    # Split declaration into type, name, parameters, attributes, and calling convention

    type, name, parameters, p_attributes, p_ccc = parse_function_signature(decl_tokens, 0)

    # Process function attributes, return type, and name
    # Some attributes may be written after the parameter list, so we need to
    # check for them and move them to the front of the declaration.
    type, attributes, ccc, parsed = parse_type(type)
    attributes += p_attributes
    ccc += p_ccc

    # Record original name without scope prefix
    decl[:unscoped_name] = name

    # Prefix name with namespace scope (if any) and then class
    decl[:name] = namespace.join('_')
    unless classname.nil?
      decl[:name] << '_' unless decl[:name].empty?
      decl[:name] << classname
    end
    # Add original name to complete fully scoped name
    decl[:name] << '_' unless decl[:name].empty?
    decl[:name] << decl[:unscoped_name]

    decl[:noreturn] = has_noreturn_attribute(attributes)
    if decl[:noreturn]
      attributes.delete_if{|attribute| is_noreturn(attribute)}
    end

    if parsed[:ptr?]
      if parsed[:const?] 
        type = [:const] + type unless type[0]==:const
        attributes.delete_if{|attr| attribute_name(attr) == "const"}
      end 
    end

    # TODO: perhaps we need a specific configuration, or use strippable to select the __attributes__ to remove.
    attributes.delete_if{|attribute| is_attribute(attribute) and (attribute_kind(attribute) == :gcc)}

    decl[:modifier] = unparse(attributes.uniq)

    if not (parsed[:c_calling_convention].nil? or parsed[:c_calling_convention].empty?)
      decl[:c_calling_convention] = parsed[:c_calling_convention] 
    end

    rettype = unparse(type).gsub(/\s+\*/,'*')
    rettype = 'void' if @local_as_void.include?(rettype.strip)
    decl[:return] = { :type       => rettype,
                      :name       => 'cmock_to_return',
                      :str        => "#{rettype} cmock_to_return",
                      :void?      => (rettype == 'void'),
                      :ptr?       => parsed[:ptr?]       || false,
                      :const?     => parsed[:const?]     || false,
                      :const_ptr? => parsed[:const_ptr?] || false }

    parameters = parameters.slice_before { |element| element == :comma }.map { |subarray| subarray.reject { |e| e == :comma } }.to_a
    # parameter is now a list of parameter declarations each being a lists of tokens.
    # eg. for (int* b, int c[5], int a=42) we'd have now (=42 has been removed earlier):
    #     [ [ :int, :mul_op, [:identifier, "b"] ],
    #       [ :int, [:identifier, "c"], [:brackets, [:integer_literal, "5"]] ],
    #       [ :int, [:identifier, "a"], :assign, [:integer_literal, "42"] ] ]

    # remove default argument statements from mock definitions
    parameters = parameters.map { |parameter|
      # type name [ = expression ]
      passign = parameter.index(:assign)
      if passign.nil?
        parameter
      else
        parameter[0..passign-1]
      end }

    # check for var args
    if parameters[-1] == [:ellipsis]
      decl[:var_arg] = "..."
      parameters.pop
      if parameters.empty?
        parameters = [:void]
      end
    else
      decl[:var_arg] = nil
    end

    if parameters.any?(nil)
      raise_parse_error "Invalid parameters #{parameters.inspect}"
    end
    parameters = clean_args(parameters)
    decl[:args_string] = parameters.map{|parameter| unparse(parameter)}.join(', ').gsub(/\s+\*/, '*')
    decl[:args] = parse_args(parameters)
    decl[:args_call] = decl[:args].map { |a| a[:name] }.join(', ')
    decl[:contains_ptr?] = decl[:args].inject(false) { |ptr, arg| arg[:ptr?] ? true : ptr }

    if decl[:return][:type].nil? || decl[:name].nil? || decl[:args].nil? ||
       decl[:return][:type].empty? || decl[:name].empty?
      raise_parse_error "  declaration: '#{declaration}'\n" \
                        "  modifier: '#{decl[:modifier]}'\n" \
                        "  noreturn: '#{decl[:noreturn]}'\n" \
                        "  return: #{prototype_inspect_hash(decl[:return])}\n" \
                        "  function: '#{decl[:name]}'\n" \
                        "  args: #{prototype_inspect_array_of_hashes(decl[:args])}\n"
    end

    decl
  end

  def prototype_inspect_hash(hash)
    pairs = []
    hash.each_pair { |name, value| pairs << ":#{name} => #{"'" if value.class == String}#{value}#{"'" if value.class == String}" }
    "{#{pairs.join(', ')}}"
  end

  def prototype_inspect_array_of_hashes(array)
    hashes = []
    array.each { |hash| hashes << prototype_inspect_hash(hash) }
    case array.size
    when 0
      return '[]'
    when 1
      return "[#{hashes[0]}]"
    else
      return "[\n    #{hashes.join("\n    ")}\n  ]\n"
    end
  end

end
