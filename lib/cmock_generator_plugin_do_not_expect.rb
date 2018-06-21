# ==========================================
#   CMock Project - Automatic Mock Generation for C
#   Copyright (c) 2015 ViCentra B.V.
#   [Released under MIT License. Please refer to license.txt for details]
# ==========================================

class CMockGeneratorPluginDoNotExpect

  attr_reader :priority
  attr_reader :config

  def initialize(config, utils)
    @config = config
    @priority = 20
  end


  def mock_function_declarations(function)
    "#define #{function[:name]}_DoNotExpect() #{function[:name]}_CMockDoNotExpect()\n" +
        "void #{function[:name]}_CMockDoNotExpect(void);\n"
  end

  def mock_interfaces(function)
    lines = "void #{function[:name]}_CMockDoNotExpect(void)\n{\n"
	lines << "  Mock.#{function[:name]}_IgnoreBool = (int)0;\n"
	lines << "  Mock.#{function[:name]}_CallInstance = CMOCK_GUTS_NONE;\n"
	lines << "}\n\n"
  end
end

