#!/bin/ruby
# =========================================================================
#   CMock - Automatic Mock Generation for C
#   ThrowTheSwitch.org
#   Copyright (c) 2007-25 Mike Karlesky, Mark VanderVoord, & Greg Williams
#   SPDX-License-Identifier: MIT
# =========================================================================

['../config/production_environment',
 'cmock_header_parser',
 'cmock_generator',
 'cmock_file_writer',
 'cmock_config',
 'cmock_plugin_manager',
 'cmock_generator_utils',
 'cmock_unityhelper_parser'].each { |req| require "#{__dir__}/#{req}" }

class CMock
  def initialize(options = nil)
    cm_config      = CMockConfig.new(options)
    cm_unityhelper = CMockUnityHelperParser.new(cm_config)
    cm_writer      = CMockFileWriter.new(cm_config)
    cm_gen_utils   = CMockGeneratorUtils.new(cm_config,
                                             :unity_helper => cm_unityhelper)
    cm_gen_plugins = CMockPluginManager.new(cm_config, cm_gen_utils)
    @cm_parser     = CMockHeaderParser.new(cm_config)
    @cm_generator  = CMockGenerator.new(cm_config, cm_writer, cm_gen_utils,
                                        cm_gen_plugins)
    @silent        = (cm_config.verbosity < 2)
  end

  def setup_mocks(files, folder = nil)
    [files].flatten.each do |src|
      generate_mock(src, folder)
    end
  end

  def setup_skeletons(files)
    [files].flatten.each do |src|
      generate_skeleton src
    end
  end

  private ###############################

  def generate_mock(src, folder)
    name = File.basename(src, '.*')
    ext = File.extname(src)
    puts "Creating mock for #{name}..." unless @silent
    @cm_generator.create_mock(name, @cm_parser.parse(name, File.read(src)), ext, folder)
  end

  def generate_skeleton(src)
    name = File.basename(src, '.*')
    puts "Creating skeleton for #{name}..." unless @silent
    @cm_generator.create_skeleton(name, @cm_parser.parse(name, File.read(src)))
  end
end

def option_maker(options, key, val)
  options ||= {}
  options[key.to_sym] =
    if val.chr == ':'
      val[1..].to_sym
    elsif val.include? ';'
      val.split(';')
    elsif val == 'true'
      true
    elsif val == 'false'
      false
    elsif val =~ /^\d+$/
      val.to_i
    else
      val
    end
  options
end

# Command Line Support ###############################

if $0 == __FILE__
  usage = "usage: ruby #{__FILE__} (-oOptionsFile) File(s)ToMock"

  unless ARGV[0]
    puts usage
    exit 1
  end

  options = {}
  filelist = []
  opt_flag = false
  ARGV.each do |arg|
    case arg
    when /^-o"?([a-zA-Z0-9@._\\\/:\s]+)"?/
      options.merge! CMockConfig.load_config_file_from_yaml(arg.gsub(/^-o/, ''))
    when /^-o$/
      opt_flag = true
    when '--skeleton'
      options[:skeleton] = true
    when '--version'
      require 'cmock_version'
      include CMockVersion
      puts CMOCK_VERSION
      exit(0)
    when /^--strippables="?(.*)"?/
      # --strippables are dealt with separately since the user is allowed to
      # enter any valid regular expression as argument
      options = option_maker(options, 'strippables', Regexp.last_match(1))
    when /^--([a-zA-Z0-9._\\\/:\s]+)="?([a-zA-Z0-9._\-\\\/:\s;@#%!$&()*]*)"?/x
      options = option_maker(options, Regexp.last_match(1),
                             Regexp.last_match(2))
    else
      if opt_flag
        options.merge! CMockConfig.load_config_file_from_yaml(arg)
        opt_flag = false
      else
        filelist << arg
      end
    end
  end

  if options[:skeleton]
    CMock.new(options).setup_skeletons(filelist)
  else
    CMock.new(options).setup_mocks(filelist)
  end
end
