require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require 'cmock_header_parser'

class CMockHeaderParserTest < Test::Unit::TestCase

  def setup
    create_mocks :config, :prototype_parser, :parsed
    @test_name = 'test_file.h'
    @config.expect.attributes.returns(['static', 'inline', '__ramfunc'])
  end

  def teardown
  end
  
  
  should "create and initialize variables to defaults appropriately" do
    @parser = CMockHeaderParser.new(@prototype_parser, "", @config, @test_name)
    assert_equal([], @parser.prototypes)
    assert_equal([], @parser.src_lines)
    assert_equal(['static', 'inline', '__ramfunc'], @parser.c_attributes)
  end
  
  
  should "strip out line comments" do
    source = 
      " abcd;\n" +
      "// hello;\n" +
      "who // is you\n"
    @parser = CMockHeaderParser.new(@prototype_parser, source, @config, @test_name)
    
    expected =
    [
      "abcd",
      "who"
    ]
    
    assert_equal(expected, @parser.src_lines)
  end
  
  
  should "remove block comments" do
    source = 
      " abcd;\n" +
      "/* hello;*/\n" +
      "who /* is you\n" +
      "// embedded line comment */\n"
    @parser = CMockHeaderParser.new(@prototype_parser, source, @config, @test_name)
    
    expected =
    [
      "abcd",
      "who"
    ]
    
    assert_equal(expected, @parser.src_lines)
  end
  
  
  should "remove preprocessor directives" do
    source = 
      "#when stuff_happens\n" +
      "#ifdef _TEST\n" +
      "#pragma stack_switch"
    @parser = CMockHeaderParser.new(@prototype_parser, source, @config, @test_name)
    
    expected = []
    
    assert_equal(expected, @parser.src_lines)
  end
  
  
  should "smush lines together that contain continuation characters" do
    source = 
      "hoo hah \\\n" +
      "when \\ \n"
    @parser = CMockHeaderParser.new(@prototype_parser, source, @config, @test_name)
    
    expected =
    [
      "hoo hah when"
    ]
    
    assert_equal(expected, @parser.src_lines)
  end
  
  
  should "remove typedef statements" do
    source = 
      "typedef uint32 (unsigned int)\n" +
      "whack me? typedef int INT\n" +
      "typedef who cares what really comes here \\\n" + # exercise multiline typedef
      "   continuation\n" +
      "this should remain!"
    @parser = CMockHeaderParser.new(@prototype_parser, source, @config, @test_name)
    
    expected =
    [
      "whack me? this should remain!"
    ]
    
    assert_equal(expected, @parser.src_lines)
  end
  
  
  should "remove defines" do
    source =
      "#define whatever you feel like defining\n" +
      "void hello(void);\n" +
      "#DEFINE I JUST DON'T CARE\n" +
      "#deFINE\n" +
      "#define get_foo() \\\n   ((Thing)foo.bar)" # exercise multiline define
          
    @parser = CMockHeaderParser.new(@prototype_parser, source, @config, @test_name)
    
    expected =
    [
      "void hello(void)",
    ]
    
    assert_equal(expected, @parser.src_lines)
  end


  should "handle odd case of typedef'd void" do  
    source =
      "typedef void SILLY_VOID_TYPE1;\n" +
      "typedef (void) SILLY_VOID_TYPE2 ;\n" +
      "typedef ( void ) (*FUNCPTR)(void);\n\n" + # don't get fooled by function pointer typedef with void as return type
      "SILLY_VOID_TYPE2 Foo(int a, unsigned int b);\n" +
      "void\n shiz(SILLY_VOID_TYPE1 *);\n" +
      "void tat(FUNCPTR);\n"
      
    @parser = CMockHeaderParser.new(@prototype_parser, source, @config, @test_name)

    expected =
    [
      "void Foo(int a, unsigned int b)",
      "void shiz(void *)",
      "void tat(FUNCPTR)"
    ]
    
    assert_equal(expected, @parser.src_lines)
  end


  should "strip default values from function parameter lists" do  
    source =
      "void Foo(int a = 57, float b=37.52, char c= 'd', char* e=\"junk\");\n"

    @parser = CMockHeaderParser.new(@prototype_parser, source, @config, @test_name)

    expected =
    [
      "void Foo(int a, float b, char c, char* e)"
    ]
    
    assert_equal(expected, @parser.src_lines)
  end


  should "raise upon empty file" do  
    source = ''
    
    @parser = CMockHeaderParser.new(@prototype_parser, source, @config, 'thinger.h')
        
    # ensure it's expected type of exception
    assert_raise RuntimeError do
      @parser.parse
    end

    assert_equal([], @parser.prototypes)
    
    # verify exception message
    begin
      @parser.parse      
    rescue RuntimeError => e
      assert_equal("No function prototypes found in 'thinger.h'", e.message)
    end    
  end


  should "raise upon no function prototypes found in file" do  
    source = 
      "typedef void SILLY_VOID_TYPE1;\n" +
      "typedef (void) SILLY_VOID_TYPE2 ;\n" +
      "typedef ( void ) (*FUNCPTR)(void);\n\n" + 
      "#define get_foo() \\\n   ((Thing)foo.bar)"
    
    @parser = CMockHeaderParser.new(@prototype_parser, source, @config, 'hello_world.h')

    # ensure it's expected type of exception
    assert_raise(RuntimeError) do
      @parser.parse
    end

    assert_equal([], @parser.prototypes)    

    # verify exception message
    begin
      @parser.parse      
    rescue RuntimeError => e
      assert_equal("No function prototypes found in 'hello_world.h'", e.message)
    end    
  end


  should "raise upon prototype parsing failure" do  
    source =
      "int Foo(int a, unsigned int b);\n" +
      "void  bar \n(uint la, int de, bool da) ; \n"
    
    @prototype_parser.expect.parse('int Foo(int a, unsigned int b)').returns(nil)
    @prototype_parser.expect.parse('int Foo(int a, unsigned int b)').returns(nil)
    
    @parser = CMockHeaderParser.new(@prototype_parser, source, @config, @test_name)

    # ensure it's expected type of exception
    assert_raise(RuntimeError) do
      @parser.parse
    end

    # verify exception message
    begin
      @parser.parse      
    rescue RuntimeError => e
      assert_equal("Failed parsing function prototype: 'int Foo(int a, unsigned int b)'", e.message)
    end    
  end


  should "extract and return function declarations" do  
    source =
      "int Foo(int a, unsigned int b);\n" +
      "void FunkyChicken (\n   uint la,\n   int de,\n   bool da) ; \n" +
      "  void \n tat();\n" +
      # following lines should yield no function prototypes:
      "#define get_foo() \\\n   (Thing)foo())\n" +
      "ARRAY_TYPE array[((U8)10)];\n" +
      "THINGER_MASK = (0x0001 << 5),\n"

    @prototype_parser.expect.parse('int Foo(int a, unsigned int b)').returns(@parsed)

    @parsed.expect.get_function_name.returns('buzz lightyear')
    @parsed.expect.get_argument_list.returns('woody')
    @parsed.expect.get_arguments.returns([{:type => 'what up', :name => 'dawg'}])
    @parsed.expect.get_return_type.returns('little')
    @parsed.expect.get_return_type_with_name.returns('bo peep')
    @parsed.expect.get_var_arg.returns('...')
    @parsed.expect.get_typedefs.returns([])
    
    @prototype_parser.expect.parse('void FunkyChicken(uint la, int de, bool da)').returns(@parsed)

    @parsed.expect.get_function_name.returns('marty')
    @parsed.expect.get_argument_list.returns('mcfly')
    @parsed.expect.get_arguments.returns([{:type => 'back', :name => 'to'}])
    @parsed.expect.get_return_type.returns('the future')
    @parsed.expect.get_return_type_with_name.returns('doc')
    @parsed.expect.get_var_arg.returns(nil)
    @parsed.expect.get_typedefs.returns([])

    @prototype_parser.expect.parse('void tat()').returns(@parsed)

    @parsed.expect.get_function_name.returns('neo')
    @parsed.expect.get_argument_list.returns('the matrix')
    @parsed.expect.get_arguments.returns([{:type => 'trinity', :name => 'the one'}])
    @parsed.expect.get_return_type.returns('agent smith')
    @parsed.expect.get_return_type_with_name.returns('morpheus')
    @parsed.expect.get_var_arg.returns('...')
    @parsed.expect.get_typedefs.returns(['typedef unsigned int UINT;', 'typedef unsigned short USHORT;'])

    expected_prototypes = 
    [
      'int Foo(int a, unsigned int b)',
      'void FunkyChicken(uint la, int de, bool da)',
      'void tat()'
    ]
    
    expected_hashes =
    [
      {
        :modifier => '',
        :args_string => 'woody',
        :return_type => 'little',
        :return_string => 'bo peep',
        :var_arg => '...',
        :args => [{:type => 'what up', :name => 'dawg'}],
        :name => 'buzz lightyear',
        :typedefs => [],
      },
      
      {
        :modifier => '',
        :args_string => 'mcfly',
        :return_type => 'the future',
        :return_string => 'doc',
        :var_arg => nil,
        :args => [{:type => 'back', :name => 'to'}],
        :name => 'marty',
        :typedefs => [],
      },

      {
        :modifier => '',
        :args_string => 'the matrix',
        :return_type => 'agent smith',
        :return_string => 'morpheus',
        :var_arg => '...',
        :args => [{:type => 'trinity', :name => 'the one'}],
        :name => 'neo',
        :typedefs => ['typedef unsigned int UINT;', 'typedef unsigned short USHORT;'],
      },
    ]

    @parser = CMockHeaderParser.new(@prototype_parser, source, @config, @test_name)
    parsed_stuff = @parser.parse
    
    assert_equal(expected_prototypes, @parser.prototypes)
    assert_equal(expected_hashes, parsed_stuff[:functions])
  end
  
  
  should "extract and return function declarations with attributes" do
    source =
      "static inline int Foo(int a, unsigned int b);\n" +
      " __ramfunc void \n tat();\n"

    @prototype_parser.expect.parse('int Foo(int a, unsigned int b)').returns(@parsed)

    @parsed.expect.get_function_name.returns('buzz lightyear')
    @parsed.expect.get_argument_list.returns('woody')
    @parsed.expect.get_arguments.returns([{:type => 'what up', :name => 'dawg'}])
    @parsed.expect.get_return_type.returns('little')
    @parsed.expect.get_return_type_with_name.returns('bo peep')
    @parsed.expect.get_var_arg.returns('...')
    @parsed.expect.get_typedefs.returns([])
    
    @prototype_parser.expect.parse('void tat()').returns(@parsed)

    @parsed.expect.get_function_name.returns('neo')
    @parsed.expect.get_argument_list.returns('the matrix')
    @parsed.expect.get_arguments.returns([{:type => 'trinity', :name => 'the one'}])
    @parsed.expect.get_return_type.returns('agent smith')
    @parsed.expect.get_return_type_with_name.returns('morpheus')
    @parsed.expect.get_var_arg.returns('...')
    @parsed.expect.get_typedefs.returns([])

    expected_prototypes = 
    [
      'int Foo(int a, unsigned int b)',
      'void tat()'
    ]
    
    expected_hashes =
    [
      {
        :modifier => 'static inline',
        :args_string => 'woody',
        :return_type => 'little',
        :return_string => 'bo peep',
        :var_arg => '...',
        :args => [{:type => 'what up', :name => 'dawg'}],
        :name => 'buzz lightyear',
        :typedefs => []
      },

      {
        :modifier => '__ramfunc',
        :args_string => 'the matrix',
        :return_type => 'agent smith',
        :return_string => 'morpheus',
        :var_arg => '...',
        :args => [{:type => 'trinity', :name => 'the one'}],
        :name => 'neo',
        :typedefs => []
      },
    ]

    @parser = CMockHeaderParser.new(@prototype_parser, source, @config, @test_name)
    parsed_stuff = @parser.parse
    
    assert_equal(expected_prototypes, @parser.prototypes)
    assert_equal(expected_hashes, parsed_stuff[:functions])
  end

end