require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"

require 'rubygems'
require 'treetop'
require 'cmock_function_prototype_node_classes'
require 'cmock_function_prototype_parser'


class CMockFunctionPrototypeParserTest < Test::Unit::TestCase

  def setup
    @parser = CMockFunctionPrototypeParser.new
  end

  def teardown
  end
  
  
  should "parse simple void function prototypes" do
    parsed = @parser.parse("void foo_bar(void)")

    assert_equal('void foo_bar(void)', parsed.get_declaration)
    assert_equal('void',    parsed.get_return_type)
    assert_equal('foo_bar', parsed.get_function_name)
    assert_equal('void',    parsed.get_argument_list)
    assert_equal([],        parsed.get_arguments)
    assert_nil(parsed.get_var_arg)

    parsed = @parser.parse("void foo_bar()")
    
    assert_equal('void foo_bar(void)', parsed.get_declaration)
    assert_equal('void',    parsed.get_return_type)
    assert_equal('foo_bar', parsed.get_function_name)
    assert_equal('void',    parsed.get_argument_list)
    assert_equal([],        parsed.get_arguments)
    assert_nil(parsed.get_var_arg)
  end


  should "fail to parse garbage, broken function prototypes, and strings that only appear to be prototypes" do
    assert_nil(@parser.parse("** !"))
    assert_nil(@parser.parse("ashjfhskdh"))
  
    assert_nil(@parser.parse("void")) # no function name or argument list
    assert_nil(@parser.parse("void foo-bar(void)")) # illegal function name
    assert_nil(@parser.parse("void foo_bar")) # no param list
    assert_nil(@parser.parse("foo_bar(void)")) # no return type
    assert_nil(@parser.parse("void ( (* const pointers[])(void) )")) # looks like function prototype but is actually array of function pointers
    assert_nil(@parser.parse("void foo_bar(int (func)(int a, char b), void (*)(void))")) # no asterisk in function pointer definition
    assert_nil(@parser.parse("unsigned int * (*(double foo, THING bar))(unsigned int a)")) # no function name
    assert_nil(@parser.parse("unsigned int * (* func(double foo, THING bar))")) # no parameter list for function pointer return
    
    assert_nil(@parser.parse("typedef void (*FUNCPTR)(void)")) # typedef string that looks like function prototype
    assert_nil(@parser.parse("(parenthetical comment)"))
  end
  
  
  should "parse and normalize white space" do
    parsed = @parser.parse("void foo_bar ( void )")
    assert_equal("void foo_bar(void)", parsed.get_declaration)
  
    parsed = @parser.parse("void foo_bar( int a,int b)")
    assert_equal("void foo_bar( int a, int b )", parsed.get_declaration)
  
    parsed = @parser.parse("void foo_bar( int a,  int b, int  ,  unsigned int  d)")
    assert_equal("void foo_bar( int a, int b, int, unsigned int d )", parsed.get_declaration)
  
    parsed = @parser.parse("unsigned  int   foo_bar(unsigned   char * const )")
    assert_equal("unsigned int foo_bar( unsigned char* const )", parsed.get_declaration)
  
    parsed = @parser.parse("int foo_bar(const unsigned char * * ptr )")
    assert_equal("int foo_bar( const unsigned char** ptr )", parsed.get_declaration)

    parsed = @parser.parse("void  foo_bar  ( int (* function) (int, char  ), void ( * ) (void ) )")
    assert_equal("void foo_bar( int (*function)( int, char ), void (*)(void) )", parsed.get_declaration)    
    
    parsed = @parser.parse("float ( * GetPtr( const   char opCode))( float,  float)")
    assert_equal("float (*GetPtr( const char opCode ))( float, float )", parsed.get_declaration)    
  end
  
  
  should "parse out arguments from an argument list into an array of hashes" do
    # function pointers & var args tested elsewhere
  
    # void is a special argument that yields no params to mock
    parsed = @parser.parse("void foo_bar(void)")
    assert_equal('void', parsed.get_argument_list)
    assert_equal([],     parsed.get_arguments)
  
    parsed = @parser.parse("void foo_bar(int a, unsigned int b)")
    assert_equal('int a, unsigned int b', parsed.get_argument_list)
    assert_equal([
      {:type => 'int', :name => 'a'},
      {:type => 'unsigned int', :name => 'b'}],
      parsed.get_arguments)
    assert_nil(parsed.get_var_arg)
  
    parsed = @parser.parse("void foo_bar(double a, float b, unsigned short c)")
    assert_equal('double a, float b, unsigned short c', parsed.get_argument_list)
    assert_equal([
      {:type => 'double', :name => 'a'},
      {:type => 'float', :name => 'b'},
      {:type => 'unsigned short', :name => 'c'}],
      parsed.get_arguments)
    assert_nil(parsed.get_var_arg)
  
    parsed = @parser.parse("void foo_bar(struct THINGER * a, struct JIMBOB b)")
    assert_equal('struct THINGER* a, struct JIMBOB b', parsed.get_argument_list)
    assert_equal([
      {:type => 'struct THINGER*', :name => 'a'},
      {:type => 'struct JIMBOB', :name => 'b'}],
      parsed.get_arguments)
    assert_nil(parsed.get_var_arg)

    parsed = @parser.parse("void foo_bar(union STARS_AND_STRIPES * a, union AFL_CIO b)")
    assert_equal('union STARS_AND_STRIPES* a, union AFL_CIO b', parsed.get_argument_list)
    assert_equal([
      {:type => 'union STARS_AND_STRIPES*', :name => 'a'},
      {:type => 'union AFL_CIO', :name => 'b'}],
      parsed.get_arguments)
    assert_nil(parsed.get_var_arg)

    # make sure primitve types in param names don't gum up the parsing works
    parsed = @parser.parse("void foo_bar(const unsigned int const_param, int int_param, int integer, char character, int* const constant)")
    assert_equal('const unsigned int const_param, int int_param, int integer, char character, int* const constant', parsed.get_argument_list)
    assert_equal([
      {:type => 'unsigned int', :name => 'const_param'},
      {:type => 'int', :name => 'int_param'},
      {:type => 'int', :name => 'integer'},
      {:type => 'char', :name => 'character'},
      {:type => 'int*', :name => 'constant'}],
      parsed.get_arguments)
    assert_nil(parsed.get_var_arg)

    # make sure custom types containing primitive names don't gum up the parsing works
    parsed = @parser.parse("void foo_bar(integer param, character thing, longint * junk, constant value)")
    assert_equal('integer param, character thing, longint* junk, constant value', parsed.get_argument_list)
    assert_equal([
      {:type => 'integer', :name => 'param'},
      {:type => 'character', :name => 'thing'},
      {:type => 'longint*', :name => 'junk'},
      {:type => 'constant', :name => 'value'}],
      parsed.get_arguments)
    assert_nil(parsed.get_var_arg)

    parsed = @parser.parse("void foo_bar(signed char * abc, const unsigned long int xyz_123, unsigned int const abc_123, long long arm_of_the_law)")
    assert_equal('signed char* abc, const unsigned long int xyz_123, unsigned int const abc_123, long long arm_of_the_law', parsed.get_argument_list)
    assert_equal([
      {:type => 'signed char*', :name => 'abc'},
      {:type => 'unsigned long int', :name => 'xyz_123'},
      {:type => 'unsigned int', :name => 'abc_123'},
      {:type => 'long long', :name => 'arm_of_the_law'}],
      parsed.get_arguments)
    assert_nil(parsed.get_var_arg)
  
    parsed = @parser.parse("void foo_bar(CUSTOM_TYPE abc, CUSTOM_TYPE* xyz_123, CUSTOM_TYPE const abcxyz, struct CUSTOM_TYPE const * const abc123)")
    assert_equal('CUSTOM_TYPE abc, CUSTOM_TYPE* xyz_123, CUSTOM_TYPE const abcxyz, struct CUSTOM_TYPE const * const abc123', parsed.get_argument_list)
    assert_equal([
      {:type => 'CUSTOM_TYPE', :name => 'abc'},
      {:type => 'CUSTOM_TYPE*', :name => 'xyz_123'},
      {:type => 'CUSTOM_TYPE', :name => 'abcxyz'},
      {:type => 'struct CUSTOM_TYPE*', :name => 'abc123'}],
      parsed.get_arguments)
    assert_nil(parsed.get_var_arg)

    parsed = @parser.parse("void foo_bar(CUSTOM_TYPE thing1[], int thing2 [ ], char thing3 [][2 ][ 3])")
    assert_equal('CUSTOM_TYPE thing1[], int thing2[], char thing3[][2][3]', parsed.get_argument_list)
    assert_equal([
      {:type => 'CUSTOM_TYPE*', :name => 'thing1'},
      {:type => 'int*', :name => 'thing2'},
      {:type => 'char*', :name => 'thing3'}],
      parsed.get_arguments)
    assert_nil(parsed.get_var_arg)
  end
  
  
  should "fail to parse arguments that mix multiple custom types or a custom type and a primitive" do
    # parser can only recognize strings of primitves followed by optional name or
    # a single custom type followed by optional name;
    # without knowing custom types a priori there's no way to parse all possible combinations
    assert_nil(@parser.parse("void foo_bar(unsigned CUSTOM_TYPE abc)"))
    assert_nil(@parser.parse("void foo_bar(CUSTOM_TYPE1 CUSTOM_TYPE2 abc)"))
    assert_nil(@parser.parse("void foo_bar(CUSTOM_TYPE, CUSTOM_TYPE1 CUSTOM_TYPE2 abc)"))
    assert_nil(@parser.parse("void foo_bar(CUSTOM_TYPE1 CUSTOM_TYPE2 abc, CUSTOM_TYPE1 CUSTOM_TYPE2 xyz)"))    
  end
  
  
  should "parse out simple return types" do
    # function pointers tested elsewhere
  
    parsed = @parser.parse("void foo_bar(void)")
    assert_equal('void', parsed.get_return_type)
  
    parsed = @parser.parse("void * foo_bar(void)")
    assert_equal('void*', parsed.get_return_type)
    assert_equal("void* #{CMOCK_RETURN_PARAM_NAME}", parsed.get_return_type_with_name)
  
    parsed = @parser.parse("unsigned  int  foo_bar(void)")
    assert_equal('unsigned int', parsed.get_return_type)
    assert_equal("unsigned int #{CMOCK_RETURN_PARAM_NAME}", parsed.get_return_type_with_name)
  
    parsed = @parser.parse("unsigned long int foo_bar(void)")
    assert_equal('unsigned long int', parsed.get_return_type)
    assert_equal("unsigned long int #{CMOCK_RETURN_PARAM_NAME}", parsed.get_return_type_with_name)
  
    parsed = @parser.parse("CUSTOM_TYPE foo_bar(void)")
    assert_equal('CUSTOM_TYPE', parsed.get_return_type)
    assert_equal("CUSTOM_TYPE #{CMOCK_RETURN_PARAM_NAME}", parsed.get_return_type_with_name)
  end
  
  
  should "normalize pointer notation" do
    parsed = @parser.parse("void * foo(unsigned int * * * a,  char * *b, int*  c, int (* func)(void), CUSTOM_TYPE const* e)")
  
    assert_equal('void*', parsed.get_return_type)
    assert_equal('unsigned int*** a, char** b, int* c, int (*func)(void), CUSTOM_TYPE const * e', parsed.get_argument_list)
    assert_equal([
       {:type => 'unsigned int***', :name => 'a'},
       {:type => 'char**', :name => 'b'},
       {:type => 'int*', :name => 'c'},
       {:type => 'FUNC_PTR_FOO_PARAM_4_T', :name => 'func'},
       {:type => 'CUSTOM_TYPE*', :name => 'e'}],
      parsed.get_arguments)
    assert_nil(parsed.get_var_arg)
  end
  
  
  should "specially process var args in preparation for mocking" do
    parsed = @parser.parse("void foo_bar(...)")
    assert_equal('void',    parsed.get_argument_list)
    assert_equal([],        parsed.get_arguments)
    assert_equal('...',     parsed.get_var_arg)
  
    parsed = @parser.parse("void foo_bar(int a, ...)")
    assert_equal('int a',   parsed.get_argument_list)
    assert_equal(
      [{:type => 'int', :name => 'a'}],
      parsed.get_arguments)
    assert_equal('...',     parsed.get_var_arg)

    parsed = @parser.parse("void thing(void (*func)(int, ...))")
    assert_equal('void (*func)( int, ... )', parsed.get_argument_list)
    assert_equal(
      [{:type => 'FUNC_PTR_THING_PARAM_1_T', :name => 'func'}],
      parsed.get_arguments)
    assert_nil(parsed.get_var_arg) # no var args for thing(), just for the function pointer param
  end
  
  
  should "parse prototypes handling function pointers" do
    # function pointer prototypes in argument lists (i.e. no typedef)

    parsed = @parser.parse("void thing(int (*func_ptr)(int, int))")
    assert_equal('void thing( int (*func_ptr)( int, int ) )', parsed.get_declaration)
    assert_equal('int (*func_ptr)( int, int )', parsed.get_argument_list)
    assert_equal(
      [{:type => 'FUNC_PTR_THING_PARAM_1_T', :name => 'func_ptr'}],
      parsed.get_arguments)

    parsed = @parser.parse("void foo(int (* const func_ptr)(int, int))")
    assert_equal('void foo( int (* const func_ptr)( int, int ) )', parsed.get_declaration)
    assert_equal('int (* const func_ptr)( int, int )', parsed.get_argument_list)
    assert_equal(
      [{:type => 'FUNC_PTR_FOO_PARAM_1_T', :name => 'func_ptr'}],
      parsed.get_arguments)

    parsed = @parser.parse("void foo_bar(void * (*func)(int *, unsigned long int, ...))")
    assert_equal('void foo_bar( void* (*func)( int*, unsigned long int, ... ) )', parsed.get_declaration)
    assert_equal('void* (*func)( int*, unsigned long int, ... )', parsed.get_argument_list)
    assert_equal(
      [{:type => 'FUNC_PTR_FOO_BAR_PARAM_1_T', :name => 'func'}],
      parsed.get_arguments)

    # note nested parens around name and arg list of first function pointer param
    parsed = @parser.parse("void foo_bar(int (((* func1)(int, char))), void (*func2)(void))")
    assert_equal('void foo_bar( int (*func1)( int, char ), void (*func2)(void) )', parsed.get_declaration)
    assert_equal('int (*func1)( int, char ), void (*func2)(void)', parsed.get_argument_list)
    assert_equal(
      [{:type => 'FUNC_PTR_FOO_BAR_PARAM_1_T', :name => 'func1'},
       {:type => 'FUNC_PTR_FOO_BAR_PARAM_2_T', :name => 'func2'}],
      parsed.get_arguments)
  
    # directly returning function pointers (i.e. no typedef)
    parsed = @parser.parse("float (*func(const char opCode))(float, float)")
    assert_equal('float (*func( const char opCode ))( float, float )', parsed.get_declaration)
    assert_equal('FUNC_PTR_FUNC_RETURN_T', parsed.get_return_type)
    assert_equal("float (*#{CMOCK_RETURN_PARAM_NAME})( float, float )", parsed.get_return_type_with_name)

    parsed = @parser.parse("void (* func (void))(void)")
    assert_equal('void (*func(void))(void)', parsed.get_declaration)
    assert_equal('FUNC_PTR_FUNC_RETURN_T', parsed.get_return_type)
    assert_equal("void (*#{CMOCK_RETURN_PARAM_NAME})(void)", parsed.get_return_type_with_name)

    parsed = @parser.parse("unsigned int * (* func(double foo, THING bar))(unsigned int)")
    assert_equal('unsigned int* (*func( double foo, THING bar ))( unsigned int )', parsed.get_declaration)
    assert_equal('FUNC_PTR_FUNC_RETURN_T', parsed.get_return_type)
    assert_equal("unsigned int* (*#{CMOCK_RETURN_PARAM_NAME})( unsigned int )", parsed.get_return_type_with_name)
  end
  
  
  should "create unique typedefs for function pointer prototypes in argument lists and return types" do
    # function prototype argument list handling
    parsed = @parser.parse("void foo_bar(unsigned int a, void (* const func)(int *, unsigned long int, ...))")
    assert_equal(
      ['typedef void (*FUNC_PTR_FOO_BAR_PARAM_2_T)( int*, unsigned long int, ... );'],
      parsed.get_typedefs)
  
    parsed = @parser.parse("void test_func(void (*)(int, char), unsigned int (*)(void))")
    assert_equal(
      ['typedef void (*FUNC_PTR_TEST_FUNC_PARAM_1_T)( int, char );',
       'typedef unsigned int (*FUNC_PTR_TEST_FUNC_PARAM_2_T)(void);'],
      parsed.get_typedefs)
  
    # function prototype return type handling
    parsed = @parser.parse("void (* func (void))(void)")
    assert_equal(
      ['typedef void (*FUNC_PTR_FUNC_RETURN_T)(void);'],
      parsed.get_typedefs)

    parsed = @parser.parse("unsigned int * (* func(double foo, THING bar))(unsigned int, ...)")
    assert_equal(
      ['typedef unsigned int* (*FUNC_PTR_FUNC_RETURN_T)( unsigned int, ... );'],
      parsed.get_typedefs)
  end
  
  
  should "insert unique names for top-level nameless arguments" do
    parsed = @parser.parse("void foo_bar(int (*)(int, int), char* const, unsigned int c, long const, CUSTOM_THING, int[], char[][2])")
  
    assert_equal(
      'int (*cmock_arg1)( int, int ), char* const cmock_arg2, unsigned int c, long const cmock_arg4, CUSTOM_THING cmock_arg5, int cmock_arg6[], char cmock_arg7[][2]',
      parsed.get_argument_list)
    assert_equal(
      [{:type => 'FUNC_PTR_FOO_BAR_PARAM_1_T', :name => 'cmock_arg1'},
       {:type => 'char*', :name => 'cmock_arg2'},
       {:type => 'unsigned int', :name => 'c'},
       {:type => 'long', :name => 'cmock_arg4'},
       {:type => 'CUSTOM_THING', :name => 'cmock_arg5'},
       {:type => 'int*', :name => 'cmock_arg6'},
       {:type => 'char*', :name => 'cmock_arg7'}],
      parsed.get_arguments)
    assert_nil(parsed.get_var_arg)
  end


end

