require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require 'cmock_header_parser'

class CMockHeaderParserTest < Test::Unit::TestCase

  def setup
    create_mocks :config, :prototype_parser, :parsed
    @config.expect.attributes.returns(['static', 'inline', '__ramfunc'])
  end

  def teardown
  end
  
  should "create and initialize variables to defaults appropriately" do
    @parser = CMockHeaderParser.new(@prototype_parser, "", @config)
    assert_equal([], @parser.prototypes)
    assert_equal([], @parser.src_lines)
    assert_equal(['static', 'inline', '__ramfunc'], @parser.c_attributes)
  end
  
  should "strip out line comments" do
    source = 
      " abcd;\n" +
      "// hello;\n" +
      "who // is you\n"
    @parser = CMockHeaderParser.new(@prototype_parser, source, @config)
    
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
    @parser = CMockHeaderParser.new(@prototype_parser, source, @config)
    
    expected =
    [
      "abcd",
      "who"
    ]
    
    assert_equal(expected, @parser.src_lines)
  end
  
  should "treat preprocessor directives as single line" do
    source = 
      "#when stuff_happens\n" +
      "#ifdef _TEST\n" +
      "#pragma stack_switch"
    @parser = CMockHeaderParser.new(@prototype_parser, source, @config)
    
    expected = []
    
    assert_equal(expected, @parser.src_lines)
  end
  
  should "smush lines together that contain continuation characters" do
    source = 
      "hoo hah \\\n" +
      "when \\ \n"
    @parser = CMockHeaderParser.new(@prototype_parser, source, @config)
    
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
    @parser = CMockHeaderParser.new(@prototype_parser, source, @config)
    
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
          
    @parser = CMockHeaderParser.new(@prototype_parser, source, @config)
    
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
      
    @parser = CMockHeaderParser.new(@prototype_parser, source, @config)

    expected =
    [
      "void Foo(int a, unsigned int b)",
      "void shiz(void *)",
      "void tat(FUNCPTR)"
    ]
    
    assert_equal(expected, @parser.src_lines)
  end

  should "raise upon prototype parsing failure" do
  
    source =
      "int Foo(int a, unsigned int b);\n" +
      "void  bar \n(uint la, int de, bool da) ; \n"
    
    @prototype_parser.expect.parse('int Foo(int a, unsigned int b)').returns(nil)
    
    @parser = CMockHeaderParser.new(@prototype_parser, source, @config)
    
    begin
      @parser.parse
      assert_fail('should have raised')
    rescue
    end
  end

  # should "extract and return function declarations" do
  # 
  #   source =
  #     "int Foo(int a, unsigned int b);\n" +
  #     "void  bar \n(uint la, int de, bool da) ; \n" +
  #     "void FunkyChicken (\n   uint la,\n   int de,\n   bool da);\n" +
  #     "void\n shiz(void);\n" +
  #     "void tat();\n" +
  #     # following lines should yield no function declarations:
  #     "#define get_foo() \\\n   (Thing)foo())\n" +
  #     "ARRAY_TYPE array[((U8)10)];\n" +
  #     "THINGER_MASK = (0x0001 << 5),\n"
  #     
  #   @parser = CMockHeaderParser.new(@prototype_parser, source, @config)
  #   parsed_stuff = @parser.parse
  #   
  #   expected =
  #   [
  #     {
  #       :modifier => "",
  #       :args_string => "int a, unsigned int b",
  #       :rettype => "int",
  #       :var_arg => nil,
  #       :args => [{:type => "int", :name => "a"}, {:type => "unsigned int", :name => "b"}],
  #       :name => "Foo"
  #     },
  #     
  #     {
  #       :modifier => "",
  #       :args_string => "uint la, int de, bool da",
  #       :rettype => "void",
  #       :var_arg => nil,
  #       :args => 
  #       [
  #         {:type => "uint", :name => "la"},
  #         {:type => "int", :name => "de"},
  #         {:type => "bool", :name => "da"}
  #       ],
  #       :name => "bar"
  #     },
  #     
  #     {
  #       :modifier => "",
  #       :args_string => "uint la, int de, bool da",
  #       :rettype => "void",
  #       :var_arg => nil,
  #       :args => 
  #       [
  #         {:type => "uint", :name => "la"},
  #         {:type => "int", :name => "de"},
  #         {:type => "bool", :name => "da"}
  #       ],
  #       :name => "FunkyChicken"
  #     },
  # 
  #     {
  #       :modifier => "",
  #       :args_string => "void",
  #       :rettype => "void",
  #       :var_arg => nil,
  #       :args => [],
  #       :name => "shiz"
  #     },
  #     
  #     {
  #       :modifier => "",
  #       :args_string => "void",
  #       :rettype => "void",
  #       :var_arg => nil,
  #       :args => [],
  #       :name => "tat"
  #     }
  #   ]
  #   
  #   assert_equal(expected, parsed_stuff[:functions])
  # end
  # 
  # should "extract and return function declarations with attributes" do
  # 
  #   source =
  #     "static \tint \n Foo(int a, unsigned int b);\n" +
  #     "inline\t bool  bar \n(uint la, int de, bool da);\n" +
  #     "inline static __ramfunc bool bar ( uint thinger );\n"
  #     
  #   @parser = CMockHeaderParser.new(@prototype_parser, source, @config)
  #   parsed_stuff = @parser.parse
  #   
  #   expected =
  #   [
  #     {
  #       :modifier => "static",
  #       :args_string => "int a, unsigned int b",
  #       :rettype => "int",
  #       :var_arg => nil,
  #       :args => [{:type => "int", :name => "a"}, {:type => "unsigned int", :name => "b"}],
  #       :name => "Foo"
  #     },
  #     
  #     {
  #       :modifier => "inline",
  #       :args_string => "uint la, int de, bool da",
  #       :rettype => "bool",
  #       :var_arg => nil,
  #       :args => 
  #       [
  #         {:type => "uint", :name => "la"},
  #         {:type => "int", :name => "de"},
  #         {:type => "bool", :name => "da"}
  #       ],
  #       :name => "bar"
  #     },
  #     
  #     {
  #       :modifier => "inline static __ramfunc",
  #       :args_string => "uint thinger",
  #       :rettype => "bool",
  #       :var_arg => nil,
  #       :args => 
  #       [
  #         {:type => "uint", :name => "thinger"},
  #       ],
  #       :name => "bar"
  #     }      
  #   ]
  #   
  #   assert_equal(expected, parsed_stuff[:functions])
  # end

end