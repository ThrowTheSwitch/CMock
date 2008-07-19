$here = File.dirname __FILE__
require "#{$here}/cmock_header_parser"
require "#{$here}/cmock_generator"
require "#{$here}/cmock_file_writer"
require "#{$here}/cmock_config"
require "#{$here}/cmock_plugin_manager"
require "#{$here}/cmock_generator_utils"

class CMock

  def initialize(mocks_path='mocks', includes=[], use_cexception=true, allow_ignore_mock=false)
    @mocks_path = mocks_path
    @includes = includes
    @use_cexception = use_cexception
    @allow_ignore_mock = allow_ignore_mock
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
    
    cm_config      = CMockConfig.new(path, @mocks_path, @includes, @use_cexception, @allow_ignore_mock)
    cm_parser      = CMockHeaderParser.new(File.read(src))
    cm_writer      = CMockFileWriter.new(cm_config)
    cm_gen_utils   = CMockGeneratorUtils.new(cm_config)
    cm_gen_plugins = CMockPluginManager.new(cm_config, cm_gen_utils).get_generator_plugins
    cm_generator   = CMockGenerator.new(cm_config, name, cm_writer, cm_gen_utils, cm_gen_plugins)
    
    puts "Creating mock for #{name}..."
    
    parsed_stuff = cm_parser.parse
    cm_generator.create_mock(parsed_stuff)
  end
end