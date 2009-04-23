require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require File.expand_path(File.dirname(__FILE__)) + "/../../lib/cmock_header_parser"

class CMockHeaderParserTest < Test::Unit::TestCase

  def setup
    create_mocks :config
    @config.expect.attributes.returns(['static', 'inline', '__ramfunc'])
  end

  def teardown
  end
  
  should "create and initialize variables to defaults appropriately" do
    @parser = CMockHeaderParser.new("", @config)
    assert_equal([], @parser.funcs)
    assert_equal(['static', 'inline', '__ramfunc'], @parser.c_attributes)
  end
  
  should "strip out line comments" do
    source = 
      " abcd;\n" +
      "// hello;\n" +
      "who // is you\n"
    @parser = CMockHeaderParser.new(source, @config)
    
    expected =
    [
      " abcd",
      "who \n"
    ]
    
    assert_equal(expected, @parser.src_lines)
  end
  
  should "remove block comments" do
    source = 
      " abcd;\n" +
      "/* hello;*/\n" +
      "who /* is you\n" +
      "// embedded line comment */\n"
    @parser = CMockHeaderParser.new(source, @config)
    
    expected =
    [
      " abcd",
      "who \n"
    ]
    
    assert_equal(expected, @parser.src_lines)
  end
  
  should "treat preprocessor directives as single line" do
    source = 
      "#when stuff_happens\n" +
      "#ifdef _TEST\n" +
      "#pragma stack_switch"
    @parser = CMockHeaderParser.new(source, @config)
    
    expected = []
    
    assert_equal(expected, @parser.src_lines)
  end
  
  should "smush lines together that contain continuation characters" do
    source = 
      "hoo hah \\\n" +
      "when \\ \n"
    @parser = CMockHeaderParser.new(source, @config)
    
    expected =
    [
      "hoo hah when "
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
    @parser = CMockHeaderParser.new(source, @config)
    
    expected =
    [
      "\nwhack me? \n\nthis should remain!"
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
      
    @parser = CMockHeaderParser.new(source, @config)
    
    expected =
    [
      "\nvoid hello(void)",
    ]
    
    assert_equal(expected, @parser.src_lines)
  end

  should "handle odd case of typedef'd void" do
  
    source =
      "typedef void SILLY_VOID_TYPE1;\n" +
      "typedef void SILLY_VOID_TYPE2 ;\n\n" +
      "SILLY_VOID_TYPE2 Foo(int a, unsigned int b);\n" +
      "void\n shiz(SILLY_VOID_TYPE1 *);\n" +
      "void tat(void);\n"
      
    @parser = CMockHeaderParser.new(source, @config)
    parsed_stuff = @parser.parse
    
    expected =
    [
      {
        :modifier => "",
        :args_string => "int a, unsigned int b",
        :rettype => "void",
        :var_arg => nil,
        :args => [{:type => "int", :name => "a"}, {:type => "unsigned int", :name => "b"}],
        :name => "Foo"
      },
      
      {
        :modifier => "",
        :args_string => "void* cmock_arg1",
        :rettype => "void",
        :var_arg => nil,
        :args => [{:type => "void*", :name => "cmock_arg1"}],
        :name => "shiz"
      },
      
      {
        :modifier => "",
        :args_string => "void",
        :rettype => "void",
        :var_arg => nil,
        :args => [],
        :name => "tat"
      }
    ]
    
    assert_equal(expected, parsed_stuff[:functions])
  end
  
  should "extract and return function declarations" do
  
    source =
      "int Foo(int a, unsigned int b);\n" +
      "void  bar \n(uint la, int de, bool da) ; \n" +
      "void FunkyChicken (\n   uint la,\n   int de,\n   bool da);\n" +
      "void\n shiz(void);\n" +
      "void tat();\n" +
      # following lines should yield no function declarations:
      "#define get_foo() \\\n   (Thing)foo())\n" +
      "ARRAY_TYPE array[((U8)10)];\n" +
      "THINGER_MASK = (0x0001 << 5),\n"
      
    @parser = CMockHeaderParser.new(source, @config)
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
        :args_string => "uint la, int de, bool da",
        :rettype => "void",
        :var_arg => nil,
        :args => 
        [
          {:type => "uint", :name => "la"},
          {:type => "int", :name => "de"},
          {:type => "bool", :name => "da"}
        ],
        :name => "FunkyChicken"
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
        :args_string => "void",
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
      "inline\t bool  bar \n(uint la, int de, bool da);\n" +
      "inline static __ramfunc bool bar ( uint thinger );\n"
      
    @parser = CMockHeaderParser.new(source, @config)
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
        :modifier => "inline",
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
      },
      
      {
        :modifier => "inline static __ramfunc",
        :args_string => "uint thinger",
        :rettype => "bool",
        :var_arg => nil,
        :args => 
        [
          {:type => "uint", :name => "thinger"},
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
      
    @parser = CMockHeaderParser.new(source, @config)
    parsed_stuff = @parser.parse
    
    expected =
    [
      {
        :modifier => "",
        :args_string => "char* const format",
        :rettype => "int",
        :var_arg => "...",
        :args => [{:type => "char* const", :name => "format"}],
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
      "MY_STRUCT* HooWah(char *** format);\n" +
      "bool* HotShot(HIS_STRUCT **p, unsigned int* pint);\n" +
      "bool * HotDog(BOW_WOW *p, unsigned int* pint);\n" +
      "bool ** HotDog(BOW_WOW* p, unsigned int* pint);\n" +
      "static bool *HotToTrot(unsigned int * struttin);\n" +
      "static bool ***HotToTrot(unsigned int ** struttin);\n"
      
    @parser = CMockHeaderParser.new(source, @config)
    parsed_stuff = @parser.parse
    
    expected =
    [
      {
        :modifier => "",
        :args_string => "char*** format",
        :rettype => "MY_STRUCT*",
        :var_arg => nil,
        :args => [{:type => "char***", :name => "format"}],
        :name => "HooWah"
      },
      
      {
        :modifier => "",
        :args_string => "HIS_STRUCT** p, unsigned int* pint",
        :rettype => "bool*",
        :var_arg => nil,
        :args => 
        [
          {:type => "HIS_STRUCT**", :name => "p"},
          {:type => "unsigned int*", :name => "pint"}
        ],
        :name => "HotShot"
      },

      {
        :modifier => "",
        :args_string => "BOW_WOW* p, unsigned int* pint",
        :rettype => "bool*",
        :var_arg => nil,
        :args => 
        [
          {:type => "BOW_WOW*", :name => "p"},
          {:type => "unsigned int*", :name => "pint"}
        ],
        :name => "HotDog"
      },
      
      {
        :modifier => "",
        :args_string => "BOW_WOW* p, unsigned int* pint",
        :rettype => "bool**",
        :var_arg => nil,
        :args => 
        [
          {:type => "BOW_WOW*", :name => "p"},
          {:type => "unsigned int*", :name => "pint"}
        ],
        :name => "HotDog"
      },
      
      {
        :modifier => "static",
        :args_string => "unsigned int* struttin",
        :rettype => "bool*",
        :var_arg => nil,
        :args => 
        [
          {:type => "unsigned int*", :name => "struttin"}
        ],
        :name => "HotToTrot"
      },

      {
        :modifier => "static",
        :args_string => "unsigned int** struttin",
        :rettype => "bool***",
        :var_arg => nil,
        :args => 
        [
          {:type => "unsigned int**", :name => "struttin"}
        ],
        :name => "HotToTrot"
      }
    ]
    
    assert_equal(expected, parsed_stuff[:functions])
  end
 
  should "extract and return function declarations with just types (no argument names)" do
  
    source =
      "int buzzlightyear(char*, bool);\n" +
      "bool woody();\n" +
      "int slinkydog(bool thing, int (* const)(void));\n" +
      "int andy(int* const);\n"
      
    @parser = CMockHeaderParser.new(source, @config)
    parsed_stuff = @parser.parse
    
    expected =
    [
      {
        :modifier => "",
        :args_string => "char* cmock_arg1, bool cmock_arg2",
        :rettype => "int",
        :var_arg => nil,
        :args => 
        [
          {:type => "char*", :name => "cmock_arg1"},
          {:type => "bool",  :name => "cmock_arg2"}
        ],
        :name => "buzzlightyear"
      },
      
      {
        :modifier => "",
        :args_string => "void",
        :rettype => "bool",
        :var_arg => nil,
        :args => [],
        :name => "woody"
      },
      
      {
        :modifier => "",
        :args_string => "bool thing, int (* const)(void) cmock_arg1",
        :rettype => "int",
        :var_arg => nil,
        :args =>
        [
          {:type => "bool", :name => "thing"},
          {:type => "int (* const)(void)",  :name => "cmock_arg1"}
        ],
        :name => "slinkydog"
      },
      
      {
        :modifier => "",
        :args_string => "int* const cmock_arg1",
        :rettype => "int",
        :var_arg => nil,
        :args =>
        [
          {:type => "int* const", :name => "cmock_arg1"},
        ],
        :name => "andy"
      }
    ]
    
    assert_equal(expected, parsed_stuff[:functions])
  end
end