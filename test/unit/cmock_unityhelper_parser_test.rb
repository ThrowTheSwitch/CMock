require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require File.expand_path(File.dirname(__FILE__)) + "/../../lib/cmock_unityhelper_parser"

class CMockUnityHelperParserTest < Test::Unit::TestCase

  def setup
    create_mocks :config
  end

  def teardown
  end
    
  should "ignore lines that are commented out" do
    source = 
      " abcd;\n" +
      "// #define TEST_ASSERT_EQUAL_CHICKENS(a,b) {...};\n" +
      "or maybe // #define TEST_ASSERT_EQUAL_CHICKENS(a,b) {...};\n\n"
    @config.expects.treat_as.returns({})
    @config.expects.load_unity_helper.returns(source)
    @parser = CMockUnityHelperParser.new(@config)
    expected = {}
    
    assert_equal(expected, @parser.c_types)
  end
  
  should "ignore stuff in block comments" do
    source = 
      " abcd; /*\n" +
      "#define TEST_ASSERT_EQUAL_CHICKENS(a,b) {...};\n" +
      "#define TEST_ASSERT_EQUAL_CHICKENS(a,b) {...};\n */\n"
    @config.expects.treat_as.returns({})
    @config.expect.load_unity_helper.returns(source)
    @parser = CMockUnityHelperParser.new(@config)
    expected = {}
    
    assert_equal(expected, @parser.c_types)
  end
  
  should "notice equal helpers in the proper form and ignore others" do
    source = 
      "abcd;\n" +
      "#define TEST_ASSERT_EQUAL_TURKEYS_T(a,b) {...};\n" +
      "abcd;\n" +
      "#define TEST_ASSERT_EQUAL_WRONG_NUM_ARGS(a,b,c) {...};\n" +
      "#define TEST_ASSERT_WRONG_NAME_EQUAL(a,b) {...};\n" +
      "#define TEST_ASSERT_EQUAL_unsigned_funky_rabbits(a,b) {...};\n" +
      "abcd;\n"
    @config.expects.treat_as.returns({})
    @config.expect.load_unity_helper.returns(source)
    @parser = CMockUnityHelperParser.new(@config)
    expected = {
      'TURKEYS_T' => "TEST_ASSERT_EQUAL_TURKEYS_T",
      'unsigned_funky_rabbits' => "TEST_ASSERT_EQUAL_unsigned_funky_rabbits"
    }
    
    assert_equal(expected, @parser.c_types)
  end

  should "notice equal helpers that contain arrays" do
    source = 
      "abcd;\n" +
      "#define TEST_ASSERT_EQUAL_TURKEYS_ARRAY(a,b,c) {...};\n" +
      "abcd;\n" +
      "#define TEST_ASSERT_EQUAL_WRONG_NUM_ARGS_ARRAY(a,b,c,d) {...};\n" +
      "#define TEST_ASSERT_WRONG_NAME_EQUAL_ARRAY(a,b,c) {...};\n" +
      "#define TEST_ASSERT_EQUAL_unsigned_funky_rabbits_ARRAY(a,b,c) {...};\n" +
      "abcd;\n"
    @config.expects.treat_as.returns({})
    @config.expect.load_unity_helper.returns(source)
    @parser = CMockUnityHelperParser.new(@config)
    expected = {
      'TURKEYS*' => "TEST_ASSERT_EQUAL_TURKEYS_ARRAY",
      'unsigned_funky_rabbits*' => "TEST_ASSERT_EQUAL_unsigned_funky_rabbits_ARRAY"
    }
    
    assert_equal(expected, @parser.c_types)
  end
  
  should "be able to fetch helpers on my list" do
    @config.expects.treat_as.returns({})
    @config.expect.load_unity_helper.returns("")
    @parser = CMockUnityHelperParser.new(@config)
    @parser.c_types = {
      'UINT8'     => "TEST_ASSERT_EQUAL_UINT8_MESSAGE",
      'UINT16*'   => "TEST_ASSERT_EQUAL_UINT16_ARRAY",
      'SPINACH'   => "TEST_ASSERT_EQUAL_SPINACH",
      'LONG_LONG' => "TEST_ASSERT_EQUAL_LONG_LONG"
    }
  
    [["UINT8","UINT8_MESSAGE"],
     ["UINT16*","UINT16_ARRAY"],
     ["const SPINACH","SPINACH"],
     ["LONG LONG","LONG_LONG"] ].each do |ctype, exptype|
      assert_equal("TEST_ASSERT_EQUAL_#{exptype}", @parser.get_helper(ctype))  
    end
  end

  should "return memory comparison when asked to fetch helper of types not on my list" do
    @config.expects.treat_as.returns({})
    @config.expect.load_unity_helper.returns("")
    @parser = CMockUnityHelperParser.new(@config)
    @parser.c_types = {
      'UINT8'   => "TEST_ASSERT_EQUAL_UINT8_MESSAGE",
      'UINT16*' => "TEST_ASSERT_EQUAL_UINT16_ARRAY",
      'SPINACH' => "TEST_ASSERT_EQUAL_SPINACH",
    }
  
    ["UINT16","UINT8*","SPINACH_T","SALAD","PINEAPPLE"].each do |ctype|
      @config.expect.memcpy_if_unknown.returns(true)
      assert_equal("TEST_ASSERT_EQUAL_MEMORY_MESSAGE", @parser.get_helper(ctype))  
    end
  end
  
  should "raise error when asked to fetch helper of type not on my list and not allowed to mem check" do
    @config.expects.treat_as.returns({})
    @config.expect.load_unity_helper.returns("")
    @config.expect.memcpy_if_unknown.returns(false)
    @parser = CMockUnityHelperParser.new(@config)
    @parser.c_types = {
      'UINT8'   => "TEST_ASSERT_EQUAL_UINT8_MESSAGE",
      'UINT16*' => "TEST_ASSERT_EQUAL_UINT16_ARRAY",
      'SPINACH' => "TEST_ASSERT_EQUAL_SPINACH",
    }
  
    assert_raise(RuntimeError) { @parser.get_helper("UINT16") }
  end
end
