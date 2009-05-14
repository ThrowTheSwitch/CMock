
require "cmock_generator_plugin_expect.rb"
require "cmock_generator_plugin_ignore.rb"
require "cmock_generator_plugin_cexception.rb"

class CMockPluginManager

  attr_accessor :plugins
  
  def initialize(config, utils)
    plugins_to_load = config.plugins
    @plugins = []
    @plugins << CMockGeneratorPluginExpect.new( config, utils ) 
    @plugins << CMockGeneratorPluginCException.new( config, utils ) if plugins_to_load.include? 'cexception'
    @plugins << CMockGeneratorPluginIgnore.new( config, utils )     if plugins_to_load.include? 'ignore'
  end
  
  def run(method, args=nil)
    if args.nil?
      return @plugins.collect{ |plugin| plugin.send(method) if plugin.respond_to?(method) }.flatten
    else
      return @plugins.collect{ |plugin| plugin.send(method, args) if plugin.respond_to?(method) }.flatten
    end
  end
end
