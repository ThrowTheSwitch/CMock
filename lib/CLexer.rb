#
# This is a simple lexer for the C programming language. 
# MIT license. (c) 2023 Pascal Bourguignon
#

class CLexer

  KEYWORDS = %w[auto break case char const continue default do double else enum
                extern float for goto if int long register return short signed
                sizeof static struct switch typedef union unsigned void volatile while].freeze

  STAR = :mul_op
  ADDRESS = :logical_and_op

  OPERATOR_SYMBOLS = {

    '...' => :ellipsis,
    '->*' => :ptr_mem_op,
    '>>=' => :right_assign,
    '<<=' => :left_assign,

    '==' => :eq,
    '!=' => :ne,
    '<=' => :le,
    '>=' => :ge,
    '>>' => :right_op,
    '<<' => :left_op,
    '+=' => :add_assign,
    '-=' => :sub_assign,
    '*=' => :mul_assign,
    '/=' => :div_assign,
    '%=' => :mod_assign,
    '&=' => :and_assign,
    '^=' => :xor_assign,
    '|=' => :or_assign,
    '->' => :ptr_op,
    '&&' => :and_op,
    '||' => :or_op,
    '++' => :increment,
    '--' => :decrement,

    '<:' => :open_bracket,
    ':>' => :close_bracket,
    '<%' => :open_brace,
    '%>' => :close_brace,

    '!' => :logical_not_op,
    '%' => :mod_op,
    '&' => :logical_and_op,
    '(' => :open_paren,
    ')' => :close_paren,
    '*' => :mul_op,
    '+' => :add_op,
    ',' => :comma,
    '-' => :sub_op,
    '.' => :dot,
    '/' => :div_op,
    ':' => :colon,
    ';' => :semicolon,
    '<' => :lt,
    '=' => :assign,
    '>' => :gt,
    '?' => :question,
    '[' => :open_bracket,
    ']' => :close_bracket,
    '^' => :logical_xor_op,
    '{' => :open_brace,
    '|' => :logical_or_op,
    '}' => :close_brace,
    '~' => :bitwise_not_op,

  }.freeze


  OPERATOR_REGEX = Regexp.new('\A(' + OPERATOR_SYMBOLS.keys.map { |op| Regexp.escape(op) }.join('|') + ')')
  OPERATOR_SYMS = OPERATOR_SYMBOLS.values.freeze
  KEYWORDS_SYMS = KEYWORDS.map{ |n| n.to_sym }.freeze

  def initialize(input)
    @input = input
    @tokens = []
  end

  def tokenize
    while @input.size > 0
      case @input
      when /\A[[:space:]]+/m
        @input = $'
      when /\A\/\/[^\n]*/
        @input = $'
      when /\A\/\*/
        consume_multiline_comment
      when /\A[_a-zA-Z][_a-zA-Z0-9]*/
        identifier_or_keyword = $& ;
        @input = $'
        if KEYWORDS.include?(identifier_or_keyword)
          @tokens << identifier_or_keyword.to_sym
        else
          @tokens << [:identifier, identifier_or_keyword]
        end
      when /\A\d+\.\d*([eE][+-]?\d+)?[fFlL]?|\.\d+([eE][+-]?\d+)?[fFlL]?|\d+[eE][+-]?\d+[fFlL]?/
        float_constant = $& ;
        @input = $'
        @tokens << [:float_literal, float_constant]
      when /\A\d+/
        integer_constant = $& ;
        @input = $'
        @tokens << [:integer_literal, integer_constant]
      when /\A0[xX][0-9a-fA-F]+/
        hex_constant = $& ;
        @input = $'
        @tokens << [:hex_literal, hex_constant]
      when /\A'((\\.|[^\\'])*)'/
        char_literal = $& ;
        @input = $'
        @tokens << [:char_literal, char_literal]
      when /\A"((\\.|[^\\"])*)"/
        string_literal = $& ;
        @input = $'
        @tokens << [:string_literal, string_literal]
      when OPERATOR_REGEX
        operator = $& ;
        @input = $'
        @tokens << OPERATOR_SYMBOLS[operator]
      else
        raise "Unexpected character: #{@input[0]}"
      end
    end

    @tokens
  end

  private

  def consume_multiline_comment
    while @input.size > 0
      case @input
      when /\A\*\//
        @input = $'
        break
      when /\A./m
        @input = $'
      end
    end
  end
end

def example 
  input = File.read("/home/pbourguignon/src/c-tidbits/pipes/tee.out.c")
  lexer = CLexer.new(input)
  tokens = lexer.tokenize
  puts tokens.inspect
end
