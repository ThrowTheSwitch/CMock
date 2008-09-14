require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require File.expand_path(File.dirname(__FILE__)) + "/../../lib/cmock_generator_utils"

class CMockGeneratorUtilsTest < Test::Unit::TestCase
  def setup
    create_mocks :config
    @config.expect.tab.returns("  ")
    @cmock_generator_utils = CMockGeneratorUtils.new(@config)
  end

  def teardown
  end
  
  should "have set up internal accessors correctly on init" do
    assert_equal(@config, @cmock_generator_utils.config)
    assert_equal("  ",    @cmock_generator_utils.tab)
  end
  
  should "set up an empty call list if no arguments passed" do
    args = []
    
    expected = ""
    returned = @cmock_generator_utils.create_call_list(args)
    assert_equal(expected, returned)
  end
  
  should "set up a single call list if one arguments passed" do
    args = [{ :type => "const char*", :name => "spoon"}]
    
    expected = "spoon"
    returned = @cmock_generator_utils.create_call_list(args)
    assert_equal(expected, returned)
  end
  
  should "set up a call list if multiple arguments passed" do
    args = [{ :type => "const char*", :name => "spoon"}, { :type => "int", :name => "fork"}, { :type => "unsigned int", :name => "knife"}]
    
    expected = "spoon, fork, knife"
    returned = @cmock_generator_utils.create_call_list(args)
    assert_equal(expected, returned)
  end
  
  should "make expand array" do
    the_type = "int"
    the_array = "array"
    new_value = "new_value"
    
    expected = ["\n",
                "  {\n",
                "    int sz = 0;\n",
                "    int *pointer = array;\n",
                "    while(pointer && pointer != arrayTail) { sz++; pointer++; }\n",
                "    if(sz == 0)\n",
                "    {\n",
                "      array = (int*)malloc(2*sizeof(int));\n",
                "      if(!array)\n",
                "        Mock.allocFailure++;\n",
                "    }\n",
                "    else\n",
                "    {\n",
                "      int *ptmp = (int*)realloc(array, sizeof(int) * (sz+1));\n",
                "      if(!ptmp)\n",
                "        Mock.allocFailure++;\n",
                "      else\n",
                "        array = ptmp;\n","    }\n",
                "    memcpy(&array[sz], &new_value, sizeof(int));\n",
                "    arrayTail = &array[sz+1];\n",
                "  }\n"
               ]
    returned = @cmock_generator_utils.make_expand_array(the_type, the_array, new_value)
    assert_equal(expected, returned)
  end
  
  should "make handle return" do 
    func_name = "Spatula"
    func_rettype = "uint64"
    indent = "[tab]"
    
    expected = ["\n",
                "[tab]if(Mock.Spatula_Return != Mock.Spatula_Return_HeadTail)\n",
                "[tab]{\n",
                "[tab]  uint64 toReturn = *Mock.Spatula_Return;\n",
                "[tab]  Mock.Spatula_Return++;\n",
                "[tab]  return toReturn;\n",
                "[tab]}\n",
                "[tab]else\n",
                "[tab]{\n",
                "[tab]  return *Mock.Spatula_Return_Head;\n",
                "[tab]}\n"
               ]
    returned = @cmock_generator_utils.make_handle_return(func_name, func_rettype, indent)
    assert_equal(expected, returned)
  end
  
  should "add new expected handler" do
    func_name = "PizzaCutter"
    var_type = "uint16"
    var_name = "Spork"
    
    expected = ["\n",
                "  {\n",
                "    int sz = 0;\n",
                "    uint16 *pointer = Mock.PizzaCutter_Expected_Spork_Head;\n",
                "    while(pointer && pointer != Mock.PizzaCutter_Expected_Spork_HeadTail) { sz++; pointer++; }\n",
                "    if(sz == 0)\n",
                "    {\n",
                "      Mock.PizzaCutter_Expected_Spork_Head = (uint16*)malloc(2*sizeof(uint16));\n",
                "      if(!Mock.PizzaCutter_Expected_Spork_Head)\n",
                "        Mock.allocFailure++;\n",
                "    }\n",
                "    else\n",
                "    {\n",
                "      uint16 *ptmp = (uint16*)realloc(Mock.PizzaCutter_Expected_Spork_Head, sizeof(uint16) * (sz+1));\n",
                "      if(!ptmp)\n",
                "        Mock.allocFailure++;\n",
                "      else\n",
                "        Mock.PizzaCutter_Expected_Spork_Head = ptmp;\n",
                "    }\n",
                "    memcpy(&Mock.PizzaCutter_Expected_Spork_Head[sz], &Spork, sizeof(uint16));\n",
                "    Mock.PizzaCutter_Expected_Spork_HeadTail = &Mock.PizzaCutter_Expected_Spork_Head[sz+1];\n",
                "  }\n",
                "  Mock.PizzaCutter_Expected_Spork = Mock.PizzaCutter_Expected_Spork_Head;\n",
                "  Mock.PizzaCutter_Expected_Spork += Mock.PizzaCutter_CallCount;\n"
               ]
    returned = @cmock_generator_utils.make_add_new_expected(func_name, var_type, var_name)
    assert_equal(expected, returned)
  end
  
  should "make handle expected for non character strings" do
    func_name = "CanOpener"
    var_type = "uint16"
    var_name = "CorkScrew"
    
    expected = ["\n",
                "  if(Mock.CanOpener_Expected_CorkScrew != Mock.CanOpener_Expected_CorkScrew_HeadTail)\n",
                "  {\n",
                "    uint16* p_expected = Mock.CanOpener_Expected_CorkScrew;\n",
                "    Mock.CanOpener_Expected_CorkScrew++;\n",
                "    TEST_ASSERT_EQUAL_MESSAGE(*p_expected, CorkScrew, \"Function 'CanOpener' called with unexpected value for parameter 'CorkScrew'.\");\n",
                "  }\n"
               ]
    returned = @cmock_generator_utils.make_handle_expected(func_name, var_type, var_name)
    assert_equal(expected, returned)
  end
  
  should "make handle expected for character strings" do
    func_name = "MeasureCup"
    var_type = "const char*"
    var_name = "TeaSpoon"
    
    expected = ["\n",
                "  if(Mock.MeasureCup_Expected_TeaSpoon != Mock.MeasureCup_Expected_TeaSpoon_HeadTail)\n",
                "  {\n",
                "    const char** p_expected = Mock.MeasureCup_Expected_TeaSpoon;\n",
                "    Mock.MeasureCup_Expected_TeaSpoon++;\n",
                "    TEST_ASSERT_EQUAL_STRING_MESSAGE(*p_expected, TeaSpoon, \"Function 'MeasureCup' called with unexpected string for parameter 'TeaSpoon'.\");\n",
                "  }\n"
               ]
    returned = @cmock_generator_utils.make_handle_expected(func_name, var_type, var_name)
    assert_equal(expected, returned)
  end
end
