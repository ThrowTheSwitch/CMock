require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require File.expand_path(File.dirname(__FILE__)) + "/../../lib/cmock_header_parser"

class CMockHeaderParserTest < Test::Unit::TestCase

  def setup
    @parser = CMockHeaderParser.new("//some contents")
  end

  def teardown
  end
  
  should "create and initialize variables to defaults appropriately" do
    @parser = CMockHeaderParser.new("//some contents")
    assert_nil(@parser.funcs)
    assert_equal(/\w+\**/, @parser.match_type)
    assert_equal(['static', '__monitor', '__ramfunc', '__irq', '__fiq'], @parser.c_attributes)
    assert_equal(/(\w*\s+)*([^\s]+)\s+(\w+)\s*\(([^\)]*)\)/, @parser.declaration_parse_matcher)
    assert_nil(@parser.included)
  end
  
  should "strip out line comments" do
    source = 
      " abcd;\n" +
      "// hello;\n" +
      "who // is you\n"
    @parser = CMockHeaderParser.new(source)
    
    expected =
    [
      " abcd",
      ";",
      "\n\nwho \n"
    ]
    
    assert_equal(expected, @parser.src_lines)
  end
  
  should "remove block comments" do
    source = 
      " abcd;\n" +
      "/* hello;*/\n" +
      "who /* is you\n" +
      "whatdya say? */\n" +
      "/* shizzzle*/"
    @parser = CMockHeaderParser.new(source)
    
    expected =
    [
      " abcd",
      ";",
      "\n\nwho \n"
    ]
    
    assert_equal(expected, @parser.src_lines)
  end
  
  should "treat preprocessor directives as single line" do
    #flunk "this substitution generates an empty first line element?"
    source = 
      "#when stuff_happens\n" +
      "#ifdef _TEST\n" +
      "#pragma stack_switch"
    @parser = CMockHeaderParser.new(source)
    
    expected =
    [
      "#when stuff_happens",
      "\n",
      "#ifdef _TEST",
      "\n",
      "#pragma stack_switch"
    ]
    
    assert_equal(expected, @parser.src_lines)
  end
  
  should "Match ; { and } as end of line characters" do
    source = 
      " i like ice cream; and i can eat { vanilla, chocolate } when I want to; so there!"
    @parser = CMockHeaderParser.new(source)
    
    expected =
    [
      " i like ice cream",
      ";",
      " and i can eat ",
      "{",
      " vanilla, chocolate ",
      "}",
      " when I want to",
      ";",
      " so there!"
    ]
    
    assert_equal(expected, @parser.src_lines)
  end
  
  should "ignore lines that contain continuation characters" do
    source = 
      "hoo hah \\\n" +
      "when \\ \n"
    @parser = CMockHeaderParser.new(source)
    
    expected =
    [
    ]
    
    assert_equal(expected, @parser.src_lines)
  end
  
  should "ignore lines that contain typedef statements" do
    source = 
      "#typedef uint32 (unsigned int)\n" +
      "whack me? #typedef int INT\n" +
      "#typedef who cares what really comes here\n" +
      "this should remain!"
    @parser = CMockHeaderParser.new(source)
    
    expected =
    [
      "\nthis should remain!"
    ]
    
    assert_equal(expected, @parser.src_lines)
  end
  
  should "remove defines" do
    source =
      "hello;\n" +
      "#define whatever you feel like defining\n" +
      "#DEFINE I JUST DON'T CARE\n" +
      "#deFINE\n"
      
    @parser = CMockHeaderParser.new(source)
    
    expected =
    [
      "hello",
      ";",
      "\n",
      "\n",
      "\n",
      "\n"
    ]
    
    assert_equal(expected, @parser.src_lines)
  end
  
  should "extract and return included files" do
    source =
      "int Foo(int a, unsigned int b);" +
      "hello;\n" +
      "#define whatever you feel like defining\n" +
      "#include \"myheader.h\"\n" +
      "#include   \t \"os.h\"\n"
      
    @parser = CMockHeaderParser.new(source)
    parsed_stuff = @parser.parse
    
    expected =
    [
      "myheader.h",
      "os.h"
    ]
    
    assert_equal(expected, parsed_stuff[:includes])
  end
  
  should "extract and return externs" do
    source =
      "extern int Foo(int a, unsigned int b);\n" +
      "extern unsigned int NumSamples;\n" +
      "extern FOO_TYPE fooFun;"
      
    @parser = CMockHeaderParser.new(source)
    
    expected =
    [
      "extern int Foo(int a, unsigned int b)",
      ";",
      "\nextern unsigned int NumSamples",
      ";",
      "\nextern FOO_TYPE fooFun",
      ";"
    ]
    
    assert_equal(expected, @parser.src_lines)
  end
  
  should "extract and return function declarations" do
  
    source =
      "int Foo(int a, unsigned int b);\n" +
      "void  bar \n(uint la, int de, bool da);\n" +
      "void\n shiz(void);\n" +
      "void tat();\n"
      
    @parser = CMockHeaderParser.new(source)
    parsed_stuff = @parser.parse
    
    expected =
    [
      {
        :modifier => "",
        :args_string => "int a, unsigned int b",
        :rettype => "int",
        :var_arg => nil,
        :args => [{:type => "int", :name => "a"}, {:type => "unsigned int", :name => "b"}],
        :name => "Foo"
      },
      
      {
        :modifier => "",
        :args_string => "uint la, int de, bool da",
        :rettype => "void",
        :var_arg => nil,
        :args => 
        [
          {:type => "uint", :name => "la"},
          {:type => "int", :name => "de"},
          {:type => "bool", :name => "da"}
        ],
        :name => "bar"
      },
      
      {
        :modifier => "",
        :args_string => "void",
        :rettype => "void",
        :var_arg => nil,
        :args => [],
        :name => "shiz"
      },
      
      {
        :modifier => "",
        :args_string => "",
        :rettype => "void",
        :var_arg => nil,
        :args => [],
        :name => "tat"
      }
    ]
    
    assert_equal(expected, parsed_stuff[:functions])
  end
  
  should "extract and return function declarations with attributes" do
  
    source =
      "static \tint \n Foo(int a, unsigned int b);\n" +
      "goodness \t bool  bar \n(uint la, int de, bool da);\n"
      
    @parser = CMockHeaderParser.new(source, /\w+\**/, ['static', 'goodness'])
    parsed_stuff = @parser.parse
    
    expected =
    [
      {
        :modifier => "static",
        :args_string => "int a, unsigned int b",
        :rettype => "int",
        :var_arg => nil,
        :args => [{:type => "int", :name => "a"}, {:type => "unsigned int", :name => "b"}],
        :name => "Foo"
      },
      
      {
        :modifier => "goodness",
        :args_string => "uint la, int de, bool da",
        :rettype => "bool",
        :var_arg => nil,
        :args => 
        [
          {:type => "uint", :name => "la"},
          {:type => "int", :name => "de"},
          {:type => "bool", :name => "da"}
        ],
        :name => "bar"
      }
    ]
    
    assert_equal(expected, parsed_stuff[:functions])
  end
  
  should "extract and return function declarations with variable argument lists" do
  
    source =
      "\tint \n printf(char * const format, ...);\n" +
      "bool  bar \n(...);\n"
      
    @parser = CMockHeaderParser.new(source)
    parsed_stuff = @parser.parse
    
    expected =
    [
      {
        :modifier => "",
        :args_string => "char * const format",
        :rettype => "int",
        :var_arg => "...",
        :args => [{:type => "char * const", :name => "format"}],
        :name => "printf"
      },
      {
        :modifier => "",
        :args_string => "void",
        :rettype => "bool",
        :var_arg => "...",
        :args => [],
        :name => "bar"
      }
    ]
    
    assert_equal(expected, parsed_stuff[:functions])
  end
  
  should "attach * to type" do
  
    source =
      "MY_STRUCT* HooWah(char * format);\n" +
      "bool* HotShot(HIS_STRUCT *p, unsigned int * pint);\n"
      
    @parser = CMockHeaderParser.new(source)
    parsed_stuff = @parser.parse
    
    expected =
    [
      {
        :modifier => "",
        :args_string => "char * format",
        :rettype => "MY_STRUCT*",
        :var_arg => nil,
        :args => [{:type => "char *", :name => "format"}],
        :name => "HooWah"
      },
      
      {
        :modifier => "",
        :args_string => "HIS_STRUCT *p, unsigned int * pint",
        :rettype => "bool*",
        :var_arg => nil,
        :args => 
        [
          {:type => "HIS_STRUCT", :name => "*p"},
          {:type => "unsigned int *", :name => "pint"}
        ],
        :name => "HotShot"
      }
    ]
    
    assert_equal(expected, parsed_stuff[:functions])
  end
  
end