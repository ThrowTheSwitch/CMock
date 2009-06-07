require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require 'cmock_header_parser'

class CMockHeaderParserTest < Test::Unit::TestCase

  def setup
    create_mocks :config, :prototype_parser, :parsed
    @test_name = 'test_file.h'
    @config.expect.attributes.returns(['__ramfunc', 'funky_attrib'])
  end

  def teardown
  end
  
  
  should "create and initialize variables to defaults appropriately" do
    @parser = CMockHeaderParser.new(@prototype_parser, "", @config, @test_name)
    assert_equal([], @parser.prototypes)
    assert_equal([], @parser.src_lines)
    assert_equal(['__ramfunc', 'funky_attrib'], @parser.attributes)
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
      "typedef uint32 (unsigned int);\n" +
      "whack me? typedef int INT;\n" +
      "typedef who cares what really comes here \\\n" + # exercise multiline typedef
      "   continuation;\n" +
      "this should remain!"
    @parser = CMockHeaderParser.new(@prototype_parser, source, @config, @test_name)
    
    expected =
    [
      "whack me? this should remain!"
    ]
    
    assert_equal(expected, @parser.src_lines)
  end


  should "remove enum statements" do
    source = 
      "enum _NamedEnum {\n" +
      " THING1 = (0x0001),\n" +
      " THING2 = (0x0001 << 5),\n" +
      "}ListOValues;\n\n" +
      "don't delete me!!\n" +
      " modifier_str enum _NamedEnum {THING1 = (0x0001), THING2 = (0x0001 << 5)} ListOValues;\n\n" +
      "typedef enum {\n" +
      " THING1,\n" +
      " THING2,\n" +
      "} Thinger;\n" +
      "or me!!\n"
    @parser = CMockHeaderParser.new(@prototype_parser, source, @config, @test_name)
    
    assert_equal(["don't delete me!! or me!!"], @parser.src_lines)
  end


  should "remove union statements" do
    source = 
      "union _NamedDoohicky {\n" +
      " unsigned int a;\n" +
      " char b;\n" +
      "} Doohicky;\n\n" +
      "I want to live!!\n" +
      "some_modifier union { unsigned int a; char b;} Whatever;\n" +
      "typedef union {\n" +
      " unsigned int a;\n" +
      " char b;\n" +
      "} Whatever;\n" +
      "me too!!\n"
    @parser = CMockHeaderParser.new(@prototype_parser, source, @config, @test_name)
    
    assert_equal(["I want to live!! me too!!"], @parser.src_lines)
  end


  should "remove struct statements" do
    source = 
      "struct _NamedStruct1 {\n" +
      " unsigned int a;\n" +
      " signed long int b;\n" +
      "} Thing ;\n\n" +
      "extern struct ForwardDeclared_t TestDataType1;\n" +
      "void foo(void);\n" +
      "struct\n"+
      "   MultilineForwardDeclared_t\n" +
      "   TestDataType2;\n" +
      "struct THINGER foo(void);\n" +
      "typedef struct {\n" +
      " unsigned int a;\n" +
      " signed char b;\n" +
      "}Thinger;\n" +
      "I want to live!!\n"
    @parser = CMockHeaderParser.new(@prototype_parser, source, @config, @test_name)

    assert_equal(["void foo(void)", "struct THINGER foo(void)", "I want to live!!"], @parser.src_lines)
  end
  
  
  should "remove externed and inline functions" do
    source = 
      " extern uint32 foobar(unsigned int);\n" +
      "uint32 extern_name_func(unsigned int);\n" +
      "uint32 funcinline(unsigned int);\n" +
      "extern void bar(unsigned int);\n" +
      "inline void bar(unsigned int);\n"
    @parser = CMockHeaderParser.new(@prototype_parser, source, @config, @test_name)
    
    expected =
    [
      "uint32 extern_name_func(unsigned int)",
      "uint32 funcinline(unsigned int)"
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
    # some code actually typedef's void even though it's not ANSI C and is, frankly, weird
    # since cmock treats void specially, we can't let void be obfuscated
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
      assert_equal("Failed parsing function prototype: 'int Foo(int a, unsigned int b)' in file '#{@test_name}'", e.message)
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
      "enum {\n" +
      "  THINGER_MASK1 = (0x0001),\n" +
      "  THINGER_MASK2 = (0x0001 << 1),\n" +
      "  THINGER_MASK3 = (0x0001 << 2) };\n" +
      "void ( ( * const Tasks [10] ) ( void ) );\n" # array of function pointers

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
  
  
  should "extract custom function attributes and also scrub certain C keywords" do
    source =
      " static int Foo( register int a, unsigned int* restrict b);\n" +
      "register __ramfunc funky_attrib void \n tat();\n"

    @prototype_parser.expect.parse('int Foo(int a, unsigned int* b)').returns(@parsed)

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
      'int Foo(int a, unsigned int* b)',
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
        :typedefs => []
      },

      {
        :modifier => '__ramfunc funky_attrib',
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


  should "not extract for mocking multiply defined prototypes" do
    # just in case a function is defined multiple times and we haven't already dealt with it
    source =
      "int Foo(int a, unsigned int b);\n" +
      "void FunkyChicken (\n   uint la,\n   int de,\n   bool da) ; \n" +
      "  void \n tat();\n" +
      "int Foo (int, unsigned int);"

    @prototype_parser.expect.parse('int Foo(int a, unsigned int b)').returns(@parsed)

    @parsed.expect.get_function_name.returns('Foo')
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

    @prototype_parser.expect.parse('int Foo(int, unsigned int)').returns(@parsed)

    @parsed.expect.get_function_name.returns('Foo')
    @parsed.expect.get_argument_list.returns('woody')
    @parsed.expect.get_arguments.returns([{:type => 'what up', :name => 'dawg'}])
    @parsed.expect.get_return_type.returns('little')
    @parsed.expect.get_return_type_with_name.returns('bo peep')
    @parsed.expect.get_var_arg.returns('...')
    @parsed.expect.get_typedefs.returns([])


    expected_prototypes = 
    [
      'int Foo(int a, unsigned int b)',
      'void FunkyChicken(uint la, int de, bool da)',
      'void tat()',
      'int Foo(int, unsigned int)'
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
        :name => 'Foo',
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

end