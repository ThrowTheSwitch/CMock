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
  
  
  should "parse out simple arguments from an argument list into an array of hashes" do
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
  
    parsed = @parser.parse("void foo_bar(int a, unsigned int b)")
    assert_equal('int a, unsigned int b', parsed.get_argument_list)
    assert_equal([
      {:type => 'int', :name => 'a'},
      {:type => 'unsigned int', :name => 'b'}],
      parsed.get_arguments)
    assert_nil(parsed.get_var_arg)
  
    parsed = @parser.parse("void foo_bar(unsigned char * abc, const unsigned long int xyz_123)")
    assert_equal('unsigned char* abc, const unsigned long int xyz_123', parsed.get_argument_list)
    assert_equal([
      {:type => 'unsigned char*', :name => 'abc'},
      {:type => 'const unsigned long int', :name => 'xyz_123'}],
      parsed.get_arguments)
    assert_nil(parsed.get_var_arg)
  
    parsed = @parser.parse("void foo_bar(CUSTOM_TYPE abc, CUSTOM_TYPE* xyz_123)")
    assert_equal('CUSTOM_TYPE abc, CUSTOM_TYPE* xyz_123', parsed.get_argument_list)
    assert_equal([
      {:type => 'CUSTOM_TYPE', :name => 'abc'},
      {:type => 'CUSTOM_TYPE*', :name => 'xyz_123'}],
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
  
    parsed = @parser.parse("unsigned  int  foo_bar(void)")
    assert_equal('unsigned int', parsed.get_return_type)
  
    parsed = @parser.parse("unsigned long int foo_bar(void)")
    assert_equal('unsigned long int', parsed.get_return_type)
  
    parsed = @parser.parse("CUSTOM_TYPE foo_bar(void)")
    assert_equal('CUSTOM_TYPE', parsed.get_return_type)
  end
  
  
  should "normalize pointer notation" do
    parsed = @parser.parse("void * foo(unsigned int * * * a,  char * *b, int*  c, int (* func)(void))")
  
    assert_equal('void*', parsed.get_return_type)
    assert_equal('unsigned int*** a, char** b, int* c, int (*func)(void)', parsed.get_argument_list)
    assert_equal([
       {:type => 'unsigned int***', :name => 'a'},
       {:type => 'char**', :name => 'b'},
       {:type => 'int*', :name => 'c'},
       {:type => 'int (*)(void)', :name => 'func'}],
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
      [{:type => 'void (*)( int, ... )', :name => 'func'}],
      parsed.get_arguments)
    assert_nil(parsed.get_var_arg) # no var args for thing(), just for the function pointer param
  end
  
  
  should "parse prototypes handling function pointers" do
    # function pointer prototypes in argument lists (i.e. no typedef)

    # handle this?  -->  "int slinkydog(bool thing, int (* const)(void));\n" +

    parsed = @parser.parse("void thing(int (*func_ptr)(int, int))")
    assert_equal('int (*func_ptr)( int, int )', parsed.get_argument_list)
    assert_equal(
      [{:type => 'int (*)( int, int )', :name => 'func_ptr'}],
      parsed.get_arguments)

    parsed = @parser.parse("void foo_bar(void * (*func)(int *, unsigned long int, ...))")
    assert_equal('void* (*func)( int*, unsigned long int, ... )', parsed.get_argument_list)
    assert_equal(
      [{:type => 'void* (*)( int*, unsigned long int, ... )', :name => 'func'}],
      parsed.get_arguments)

    parsed = @parser.parse("void foo_bar(int (* func1)(int a, char b), void (*func2)(void))")
    assert_equal('int (*func1)( int a, char b ), void (*func2)(void)', parsed.get_argument_list)
    assert_equal(
      [{:type => 'int (*)( int a, char b )', :name => 'func1'},
       {:type => 'void (*)(void)', :name => 'func2'}],
      parsed.get_arguments)
  
    # directly returning function pointers (i.e. no typedef)
    parsed = @parser.parse("float (*func(const char opCode))(float, float)")
    assert_equal('float (*)( float, float )', parsed.get_return_type)

    parsed = @parser.parse("void (*func (void))(void)")
    assert_equal('void (*)(void)', parsed.get_return_type)

    parsed = @parser.parse("unsigned int * (* func(double foo, THING bar))(unsigned int a)")
    assert_equal('unsigned int* (*)( unsigned int a )', parsed.get_return_type)
  end
  
  
  should "create unique typedefs for function pointer prototypes in argument lists and return types" do
    # function prototype argument list handling
    parsed = @parser.parse("void foo_bar(unsigned int a, void (*func)(int *, unsigned long int, ...))")
    assert_equal(
      [{:type => 'void (*)( int*, unsigned long int, ... )',
        :typename => 'FUNC_PTR_FOO_BAR_PARAM_2_T',
        :typedef => 'typedef void (*FUNC_PTR_FOO_BAR_PARAM_2_T)( int*, unsigned long int, ... );'}],
      parsed.get_typedefs)
  
    parsed = @parser.parse("void test_func(void (*)(int, char), unsigned int (*)(void))")
    assert_equal(
      [{:type => 'void (*)( int, char )',
        :typename => 'FUNC_PTR_TEST_FUNC_PARAM_1_T',
        :typedef => 'typedef void (*FUNC_PTR_TEST_FUNC_PARAM_1_T)( int, char );'},
       {:type => 'unsigned int (*)(void)',
        :typename => 'FUNC_PTR_TEST_FUNC_PARAM_2_T',
        :typedef => 'typedef unsigned int (*FUNC_PTR_TEST_FUNC_PARAM_2_T)(void);'}],
      parsed.get_typedefs)
  
    # function prototype return type handling
    parsed = @parser.parse("void (*func (void))(void)")
    assert_equal(
      [{:type => 'void (*)(void)',
        :typename => 'FUNC_PTR_FUNC_RETURN_T',
        :typedef => 'typedef void (*FUNC_PTR_FUNC_RETURN_T)(void);'}],
      parsed.get_typedefs)

    parsed = @parser.parse("unsigned int * (* func(double foo, THING bar))(unsigned int, ...)")
    assert_equal(
      [{:type => 'unsigned int* (*)( unsigned int, ... )',
        :typename => 'FUNC_PTR_FUNC_RETURN_T',
        :typedef => 'typedef unsigned int* (*FUNC_PTR_FUNC_RETURN_T)( unsigned int, ... );'}],
      parsed.get_typedefs)
  end
  
  
  should "insert unique names for top-level nameless arguments" do
    parsed = @parser.parse("void foo_bar(int (*)(int, int), char* const, unsigned int c, CUSTOM_THING)")
  
    assert_equal('int (*cmock_arg1)( int, int ), char* const cmock_arg2, unsigned int c, CUSTOM_THING cmock_arg4', parsed.get_argument_list)
    assert_equal(
      [{:type => 'int (*)( int, int )', :name => 'cmock_arg1'},
       {:type => 'char* const', :name => 'cmock_arg2'},
       {:type => 'unsigned int', :name => 'c'},
       {:type => 'CUSTOM_THING', :name => 'cmock_arg4'}],
      parsed.get_arguments)
    assert_nil(parsed.get_var_arg)
  end


end

