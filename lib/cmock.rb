# ==========================================
#   CMock Project - Automatic Mock Generation for C
#   Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
#   [Released under MIT License. Please refer to license.txt for details]
# ========================================== 

[ "../config/production_environment",
  "cmock_header_parser",
  "cmock_generator",
  "cmock_file_writer",
  "cmock_config",
  "cmock_plugin_manager",
  "cmock_generator_utils",
  "cmock_unityhelper_parser"].each {|req| require "#{File.expand_path(File.dirname(__FILE__))}/#{req}"}

class CMock

  attr_accessor :target_folder
  
  def initialize(options=nil)
    cm_config      = CMockConfig.new(options)    
    cm_unityhelper = CMockUnityHelperParser.new(cm_config)
    @cm_writer      = CMockFileWriter.new(cm_config)
    cm_gen_utils   = CMockGeneratorUtils.new(cm_config, {:unity_helper => cm_unityhelper})
    cm_gen_plugins = CMockPluginManager.new(cm_config, cm_gen_utils)
    @cm_parser     = CMockHeaderParser.new(cm_config)
    @cm_generator  = CMockGenerator.new(cm_config, @cm_writer, cm_gen_utils, cm_gen_plugins)
    @silent        = (cm_config.verbosity < 2)
  end
  
  def setup_mocks(fileintrinsics, filedefns, fileothers, source_folder, target_folder, unity_folder, unity_files, cmock_folder, cmock_files, exclusion_file)

    #non_mocked_files = []
    
    # read the exclusion list and exclude the files there from src below
    if (exclusion_file != '')
      exclusion_list = parse_exclusion_list(exclusion_file)
    end

    [fileintrinsics].flatten.uniq.each do |src|

      if (exclusion_file != '')
        name = File.basename(src)
        if (!exclusion_list.include?(name))
          generate_mock(src, filedefns, target_folder)
        else
          # Code here to copy file instead of mocking
          fileothers << "#{name}"
        end
      else
        generate_mock(src, filedefns, target_folder)
      end
    end
    #@cm_writer.copy_files(source_folder, target_folder, non_mocked_files)
    @cm_writer.copy_files(source_folder, target_folder, filedefns)
    @cm_writer.copy_files(source_folder, target_folder, fileothers)
    @cm_writer.copy_files(unity_folder, target_folder, unity_files)
    @cm_writer.copy_files(cmock_folder, target_folder, cmock_files)
  end

  private ###############################

  def generate_mock(src, filedefns, target_folder)
    defninclude = ''
    name = File.basename(src, '.h')
    modulename = name.slice(/[a-zA-Z0-9]+/)
    [filedefns].flatten.each do |defns|
      if (defns.match(/\A#{modulename}_defns.h/))
        defninclude = "#include \"#{defns}\"\n"
      end
    end
    puts "Creating mock for #{name}..." unless @silent
    @cm_generator.create_mock(name, defninclude, @cm_parser.parse(name, File.read(src)), target_folder)
  end
  
  def parse_exclusion_list(exclusion_file)  
    exclusion_list = []
    source = File.read(exclusion_file)
    source.gsub!(/\r/,'')
    source.gsub!(/\n/,'')
    exclusion_list = source.split(/\s*;\s*/)
    exclusion_list.delete_if {|line| line.strip.length == 0}
    exclusion_list = exclusion_list.flatten

    return exclusion_list
  end
  
end

  # Command Line Support ###############################
  
if ($0 == __FILE__)
  usage = "usage: ruby #{__FILE__} SourceFolder UnitySourceFolder CMockSourceFolder TargetFolder ExclusionList.txt(optional)"
  
  if (ARGV.length < 4)
    puts usage
    exit 1
  end

  options = nil
  fileintrinsics = []
  filedefns = []
  fileothers = []
  unity_files = []
  cmock_files = []
  exclusion_file = ''

  source_folder = ARGV.fetch(0)
  unity_folder = ARGV.fetch(1)
  cmock_folder = ARGV.fetch(2)
  target_folder = ARGV.fetch(3)
  
  if (ARGV.length == 5)
    exclusion_file = ARGV.fetch(4)
  end

    # Doing a directory search for header files.
  Dir.foreach(source_folder) do |file|
    if (file.length > 2)
      if (!file.start_with?("."))
        if (file.match(/.*_intrinsics/))
          fileintrinsics << "#{source_folder}\\#{file}"
        elsif (file.match(/.*_defns/))
          filedefns << "#{file}"
        else
          fileothers << "#{file}"
        end
      end
    end
  end

  Dir.foreach(unity_folder) do |file|
    if (file.length > 2)
      unity_files << "#{file}"
    end
  end

  Dir.foreach(cmock_folder) do |file|
    if (file.length > 2)
      cmock_files << "#{file}"
    end
  end
  
  CMock.new(options).setup_mocks(fileintrinsics, filedefns, fileothers, source_folder, target_folder, unity_folder, unity_files, cmock_folder, cmock_files, exclusion_file)

end