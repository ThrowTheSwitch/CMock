
require "#{$here}/cmock_generator_plugin_expect.rb"
require "#{$here}/cmock_generator_plugin_ignore.rb"
require "#{$here}/cmock_generator_plugin_cexception.rb"

class CMockPluginManager

  attr_reader :config, :utils

  def initialize(config, utils)
    @config = config
    @utils = utils
  end
  
  def get_generator_plugins
    plugins_to_load = @config.plugins
  	@plugins = []
  	@plugins << CMockGeneratorPluginExpect.new( @config, @utils ) 
  	@plugins << CMockGeneratorPluginCException.new( @config, @utils ) if plugins_to_load.include? 'cexception'
  	@plugins << CMockGeneratorPluginIgnore.new( @config, @utils )     if plugins_to_load.include? 'ignore'
    return @plugins
  end
end
