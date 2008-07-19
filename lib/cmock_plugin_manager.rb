
require "#{$here}/cmock_generator_plugin_expect.rb"
require "#{$here}/cmock_generator_plugin_ignore.rb"
require "#{$here}/cmock_generator_plugin_cexception.rb"

class CMockPluginManager

  def initialize(config, utils)
    @config = config
    @utils = utils
  end
  
  def get_generator_plugins
  	@plugins = []
  	@plugins << CMockGeneratorPluginExpect.new( @config, @utils ) 
  	@plugins << CMockGeneratorPluginCException.new( @config, @utils ) if @config.use_cexception
  	@plugins << CMockGeneratorPluginIgnore.new( @config, @utils ) if @config.allow_ignore_mock
    return @plugins
  end
end

#!!!!!!!!!!!!!!!!!!!!!!!!!  eventually I plan to scan a plugin directory to pull in all this stuff, and maybe check the yaml file after that to see what is currently allowed.  that sounds swank, no?
