class CMockGeneratorPluginValidatePtrAddress
  attr_reader :priority
  attr_accessor :utils

  def initialize(config, utils)
    @utils        = utils
    @priority     = 4
  end

  def instance_typedefs(function)
    lines = ""
    function[:args].each do |arg|
      if (@utils.ptr_or_str?(arg[:type]) and not arg[:const?])
        lines << "  int ValidateAddressArg_#{arg[:name]};\n"
      end
    end
    lines
  end

  def mock_function_declarations(function)
    lines = ""
    function[:args].each do |arg|
      if (@utils.ptr_or_str?(arg[:type]) and not arg[:const?])
        lines << "#define #{function[:name]}_ValidateAddress_#{arg[:name]}()"
        lines << " #{function[:name]}_CMockValidateAddress_#{arg[:name]}(__LINE__)\n"
        lines << "void #{function[:name]}_CMockValidateAddress_#{arg[:name]}(UNITY_LINE_TYPE cmock_line);\n"
      end
    end
    lines
  end

  def mock_interfaces(function)
    lines = []
    func_name = function[:name]
    function[:args].each do |arg|
      arg_name = arg[:name]
      arg_type = arg[:type]
      if (@utils.ptr_or_str?(arg[:type]) and not arg[:const?])
        lines << "void #{func_name}_CMockValidateAddress_#{arg_name}(UNITY_LINE_TYPE cmock_line)\n"
        lines << "{\n"
        lines << "  CMOCK_#{func_name}_CALL_INSTANCE* cmock_call_instance = " +
          "(CMOCK_#{func_name}_CALL_INSTANCE*)CMock_Guts_GetAddressFor(CMock_Guts_MemEndOfChain(Mock.#{func_name}_CallInstance));\n"
        lines << "  UNITY_TEST_ASSERT_NOT_NULL(cmock_call_instance, cmock_line, CMockStringPtrPreExp);\n"
        lines << "  cmock_call_instance->ValidateAddressArg_#{arg_name} = 1;\n"
        lines << "}\n\n"
      end
    end
    lines
  end

  def mock_implementation(function)
    lines = []
    function[:args].each do |arg|
      arg_name = arg[:name]
      arg_type = arg[:type]
      expected   = "cmock_call_instance->Expected_#{arg_name}"
      if (@utils.ptr_or_str?(arg[:type]) and not arg[:const?])
        lines << "  if (cmock_call_instance->ValidateAddressArg_#{arg_name})\n"
        lines << "  {\n"
        lines << "    if (#{expected} == NULL)\n"
        lines << "    {\n"
        lines << "      UNITY_TEST_ASSERT_NULL(#{arg_name}, cmock_line, CMockStringExpNULL);\n"
        lines << "    }\n"
        lines << "    else\n"
        lines << "    {\n"
        lines << "      UNITY_TEST_ASSERT_EQUAL_PTR(#{expected}, #{arg_name}, cmock_line, CMockStringMismatch);\n"
        lines << "    }\n"
        lines << "  }\n"
      end
    end
    lines
  end
end