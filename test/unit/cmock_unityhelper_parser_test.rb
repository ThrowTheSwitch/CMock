# ==========================================
#   CMock Project - Automatic Mock Generation for C
#   Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
#   [Released under MIT License. Please refer to license.txt for details]
# ========================================== 

require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require 'cmock_unityhelper_parser'

class CMockUnityHelperParserTest < Test::Unit::TestCase

  def setup
    create_mocks :config
  end

  def teardown
  end
    
  should "ignore lines that are commented out" do
    source = 
      " abcd;\n" +
      "// #define UNITY_TEST_ASSERT_EQUAL_CHICKENS(a,b,line,msg) {...};\n" +
      "or maybe // #define UNITY_TEST_ASSERT_EQUAL_CHICKENS(a,b,line,msg) {...};\n\n"
    @config.expects.plugins.returns([]) #not :array
    @config.expects.treat_as.returns({})
    @config.expects.load_unity_helper.returns(source)
    @parser = CMockUnityHelperParser.new(@config)
    expected = {}
    
    assert_equal(expected, @parser.c_types)
  end
  
  should "ignore stuff in block comments" do
    source = 
      " abcd; /*\n" +
      "#define UNITY_TEST_ASSERT_EQUAL_CHICKENS(a,b,line,msg) {...};\n" +
      "#define UNITY_TEST_ASSERT_EQUAL_CHICKENS(a,b,line,msg) {...};\n */\n"
    @config.expects.plugins.returns([]) #not :array
    @config.expects.treat_as.returns({})
    @config.expect.load_unity_helper.returns(source)
    @parser = CMockUnityHelperParser.new(@config)
    expected = {}
    
    assert_equal(expected, @parser.c_types)
  end
  
  should "notice equal helpers in the proper form and ignore others" do
    source = 
      "abcd;\n" +
      "#define UNITY_TEST_ASSERT_EQUAL_TURKEYS_T(a,b,line,msg) {...};\n" +
      "abcd;\n" +
      "#define UNITY_TEST_ASSERT_EQUAL_WRONG_NUM_ARGS(a,b,c,d,e) {...};\n" +
      "#define UNITY_TEST_ASSERT_WRONG_NAME_EQUAL(a,b,c,d) {...};\n" +
      "#define UNITY_TEST_ASSERT_EQUAL_unsigned_funky_rabbits(a,b,c,d) {...};\n" +
      "abcd;\n"
    @config.expects.plugins.returns([]) #not :array
    @config.expects.treat_as.returns({})
    @config.expect.load_unity_helper.returns(source)
    @parser = CMockUnityHelperParser.new(@config)
    expected = {
      'TURKEYS_T' => "UNITY_TEST_ASSERT_EQUAL_TURKEYS_T",
      'unsigned_funky_rabbits' => "UNITY_TEST_ASSERT_EQUAL_unsigned_funky_rabbits"
    }
    
    assert_equal(expected, @parser.c_types)
  end

  should "notice equal helpers that contain arrays" do
    source = 
      "abcd;\n" +
      "#define UNITY_TEST_ASSERT_EQUAL_TURKEYS_ARRAY(a,b,c,d,e) {...};\n" +
      "abcd;\n" +
      "#define UNITY_TEST_ASSERT_EQUAL_WRONG_NUM_ARGS_ARRAY(a,b,c,d,e,f) {...};\n" +
      "#define UNITY_TEST_ASSERT_WRONG_NAME_EQUAL_ARRAY(a,b,c,d,e) {...};\n" +
      "#define UNITY_TEST_ASSERT_EQUAL_unsigned_funky_rabbits_ARRAY(a,b,c,d,e) {...};\n" +
      "abcd;\n"
    @config.expects.plugins.returns([]) #not :array
    @config.expects.treat_as.returns({})
    @config.expect.load_unity_helper.returns(source)
    @parser = CMockUnityHelperParser.new(@config)
    expected = {
      'TURKEYS*' => "UNITY_TEST_ASSERT_EQUAL_TURKEYS_ARRAY",
      'unsigned_funky_rabbits*' => "UNITY_TEST_ASSERT_EQUAL_unsigned_funky_rabbits_ARRAY"
    }
    
    assert_equal(expected, @parser.c_types)
  end

  should "pull in the standard set of helpers and add them to my list" do
    pairs = {
      "UINT"          => "HEX32",
      "unsigned long" => "HEX64",
    }
    expected = {
      "UINT"          => "UNITY_TEST_ASSERT_EQUAL_HEX32",
      "unsigned_long" => "UNITY_TEST_ASSERT_EQUAL_HEX64",
      "UINT*"         => "UNITY_TEST_ASSERT_EQUAL_HEX32_ARRAY",
      "unsigned_long*"=> "UNITY_TEST_ASSERT_EQUAL_HEX64_ARRAY",
    }
    @config.expects.plugins.returns([]) #not :array
    @config.expects.treat_as.returns(pairs)
    @config.expect.load_unity_helper.returns(nil)
    @parser = CMockUnityHelperParser.new(@config)
    
    assert_equal(expected, @parser.c_types)
  end
  
  should "pull in the user specified set of helpers and add them to my list" do
    pairs = {
      "char*"         => "STRING",
      "unsigned  int" => "HEX32",
    }
    expected = {
      "char*"         => "UNITY_TEST_ASSERT_EQUAL_STRING",
      "unsigned_int"  => "UNITY_TEST_ASSERT_EQUAL_HEX32",
      "char**"        => "UNITY_TEST_ASSERT_EQUAL_STRING_ARRAY",
      "unsigned_int*" => "UNITY_TEST_ASSERT_EQUAL_HEX32_ARRAY",
    }
    @config.expects.plugins.returns([]) #not :array
    @config.expects.treat_as.returns(pairs)
    @config.expect.load_unity_helper.returns(nil)
    @parser = CMockUnityHelperParser.new(@config)
    
    assert_equal(expected, @parser.c_types)
  end
  
  should "be able to fetch helpers on my list" do
    @config.expects.plugins.returns([]) #not :array
    @config.expects.treat_as.returns({})
    @config.expect.load_unity_helper.returns("")
    @parser = CMockUnityHelperParser.new(@config)
    @parser.c_types = {
      'UINT8'     => "UNITY_TEST_ASSERT_EQUAL_UINT8",
      'UINT16*'   => "UNITY_TEST_ASSERT_EQUAL_UINT16_ARRAY",
      'SPINACH'   => "UNITY_TEST_ASSERT_EQUAL_SPINACH",
      'LONG_LONG' => "UNITY_TEST_ASSERT_EQUAL_LONG_LONG"
    }
  
    [["UINT8","UINT8"],
     ["UINT16*","UINT16_ARRAY"],
     ["const SPINACH","SPINACH"],
     ["LONG LONG","LONG_LONG"] ].each do |ctype, exptype|
      assert_equal(["UNITY_TEST_ASSERT_EQUAL_#{exptype}",''], @parser.get_helper(ctype))  
    end
  end

  should "return memory comparison when asked to fetch helper of types not on my list" do
    @config.expects.plugins.returns([]) #not :array
    @config.expects.treat_as.returns({})
    @config.expects.load_unity_helper.returns("")
    @parser = CMockUnityHelperParser.new(@config)
    @parser.c_types = {
      'UINT8'   => "UNITY_TEST_ASSERT_EQUAL_UINT8",
      'UINT16*' => "UNITY_TEST_ASSERT_EQUAL_UINT16_ARRAY",
      'SPINACH' => "UNITY_TEST_ASSERT_EQUAL_SPINACH",
    }
  
    ["UINT32","SPINACH_T","SALAD","PINEAPPLE"].each do |ctype|
      @config.expect.memcmp_if_unknown.returns(true)
      assert_equal(["UNITY_TEST_ASSERT_EQUAL_MEMORY",'&'], @parser.get_helper(ctype))  
    end
  end

  should "return memory array comparison when asked to fetch helper of types not on my list" do
    @config.expects.plugins.returns([:array])
    @config.expects.treat_as.returns({})
    @config.expects.load_unity_helper.returns("")
    @parser = CMockUnityHelperParser.new(@config)
    @parser.c_types = {
      'UINT8'   => "UNITY_TEST_ASSERT_EQUAL_UINT8",
      'UINT16*' => "UNITY_TEST_ASSERT_EQUAL_UINT16_ARRAY",
      'SPINACH' => "UNITY_TEST_ASSERT_EQUAL_SPINACH",
    }
  
    ["UINT32*","SPINACH_T*"].each do |ctype|
      @config.expect.memcmp_if_unknown.returns(true)
      assert_equal(["UNITY_TEST_ASSERT_EQUAL_MEMORY_ARRAY",''], @parser.get_helper(ctype))  
    end
  end
  
  should "return the array handler if we cannot find the normal handler" do
    @config.expects.plugins.returns([]) #not :array
    @config.expects.treat_as.returns({})
    @config.expect.load_unity_helper.returns("")
    @parser = CMockUnityHelperParser.new(@config)
    @parser.c_types = {
      'UINT8'   => "UNITY_TEST_ASSERT_EQUAL_UINT8",
      'UINT16*' => "UNITY_TEST_ASSERT_EQUAL_UINT16_ARRAY",
      'SPINACH' => "UNITY_TEST_ASSERT_EQUAL_SPINACH",
    }
  
      assert_equal(["UNITY_TEST_ASSERT_EQUAL_UINT16_ARRAY",'&'], @parser.get_helper("UINT16"))  
  end
  
  should "return the normal handler if we cannot find the array handler" do
    @config.expects.plugins.returns([]) #not :array
    @config.expects.treat_as.returns({})
    @config.expect.load_unity_helper.returns("")
    @parser = CMockUnityHelperParser.new(@config)
    @parser.c_types = {
      'UINT8'   => "UNITY_TEST_ASSERT_EQUAL_UINT8",
      'UINT16'  => "UNITY_TEST_ASSERT_EQUAL_UINT16",
      'SPINACH' => "UNITY_TEST_ASSERT_EQUAL_SPINACH",
    }
  
      assert_equal(["UNITY_TEST_ASSERT_EQUAL_UINT8",'*'], @parser.get_helper("UINT8*"))  
  end
  
  should "raise error when asked to fetch helper of type not on my list and not allowed to mem check" do
    @config.expects.plugins.returns([]) #not :array
    @config.expects.treat_as.returns({})
    @config.expect.load_unity_helper.returns("")
    @config.expect.memcmp_if_unknown.returns(false)
    @parser = CMockUnityHelperParser.new(@config)
    @parser.c_types = {
      'UINT8'   => "UNITY_TEST_ASSERT_EQUAL_UINT8",
      'UINT32*' => "UNITY_TEST_ASSERT_EQUAL_UINT32_ARRAY",
      'SPINACH' => "UNITY_TEST_ASSERT_EQUAL_SPINACH",
    }
  
    assert_raise(RuntimeError) { @parser.get_helper("UINT16") }
  end
end
