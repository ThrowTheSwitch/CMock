# ==========================================
#   CMock Project - Automatic Mock Generation for C
#   Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
#   [Released under MIT License. Please refer to license.txt for details]
# ========================================== 

require File.expand_path(File.dirname(__FILE__)) + "/../config/production_environment"

require "cmock_header_parser"
require "cmock_generator"
require "cmock_file_writer"
require "cmock_config"
require "cmock_plugin_manager"
require "cmock_generator_utils"
require "cmock_unityhelper_parser"

class CMock
  
  def initialize(options=nil)
    cm_config      = CMockConfig.new(options)    
    cm_unityhelper = CMockUnityHelperParser.new(cm_config)
    cm_writer      = CMockFileWriter.new(cm_config)
    cm_gen_utils   = CMockGeneratorUtils.new(cm_config, {:unity_helper => cm_unityhelper})
    cm_gen_plugins = CMockPluginManager.new(cm_config, cm_gen_utils)
    @cm_parser     = CMockHeaderParser.new(cm_config)
    @cm_generator  = CMockGenerator.new(cm_config, cm_writer, cm_gen_utils, cm_gen_plugins)
    @silent        = (cm_config.verbosity < 2)
  end
  
  def setup_mocks(files)
    [files].flatten.each do |src|
      generate_mock src
    end
  end

  private ###############################

  def generate_mock(src)
    name = File.basename(src, '.h')
    puts "Creating mock for #{name}..." unless @silent
    @cm_generator.create_mock(name, @cm_parser.parse(name, File.read(src)))
  end
end

  # Command Line Support ###############################
  
if ($0 == __FILE__)
  usage = "usage: ruby #{__FILE__} (-oOptionsFile) File(s)ToMock"
  
  if (!ARGV[0])
    puts usage
    exit 1
  end
  
  options = nil
  filelist = []
  ARGV.each do |arg|
    if (arg =~ /^-o(\w*)/)
      options = arg.gsub(/^-o/,'')
    else
      filelist << arg
    end
  end
  
  CMock.new(options).setup_mocks(filelist)
end