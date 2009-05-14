require File.expand_path(File.dirname(__FILE__)) + "/../config/production_environment"

require "cmock_function_prototype_node_classes"
require "cmock_function_prototype_parser"
require "cmock_header_parser"
require "cmock_generator"
require "cmock_file_writer"
require "cmock_config"
require "cmock_plugin_manager"
require "cmock_generator_utils"
require "cmock_unityhelper_parser"


class CMock
  
  def initialize(options=nil)
    @cfg = CMockConfig.new(options)
  end
  
  def setup_mocks(files)
    files.each do |src|
      generate_mock src
    end
  end

  private ###############################

  def generate_mock(src)
    name = File.basename(src, '.h')
    path = File.dirname(src)
    @cfg.set_path(path)
    
    cm_parser      = CMockHeaderParser.new(CMockFunctionPrototypeParser.new, File.read(src), @cfg, name)
    cm_unityhelper = CMockUnityHelperParser.new(@cfg)
    cm_writer      = CMockFileWriter.new(@cfg)
    cm_gen_utils   = CMockGeneratorUtils.new(@cfg, {:unity_helper => cm_unityhelper})
    cm_gen_plugins = CMockPluginManager.new(@cfg, cm_gen_utils)
    cm_generator   = CMockGenerator.new(@cfg, name, cm_writer, cm_gen_utils, cm_gen_plugins)
    
    puts "Creating mock for #{name}..."
    
    parsed_stuff = cm_parser.parse
    cm_generator.create_mock(parsed_stuff)
  end
end

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