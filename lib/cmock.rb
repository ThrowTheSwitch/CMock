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
  
  def setup_mocks(fileintrinsics, filedefns, fileothers, source_folder, target_folder)
    [fileintrinsics].flatten.uniq.each do |src|
      generate_mock(src, filedefns, target_folder)
    end
	@cm_writer.copy_files(source_folder, target_folder, filedefns)
    @cm_writer.copy_files(source_folder, target_folder, fileothers)
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
end

  # Command Line Support ###############################
  
if ($0 == __FILE__)
  usage = "usage: ruby #{__FILE__} (-oOptionsFile) SourceFolder"
  
  if (!ARGV[0])
    puts usage
    exit 1
  end
  
  options = nil
  fileintrinsics = []
  filedefns = []
  fileothers = []

#  ARGV.each do |arg|
#	Dir.foreach(arg) do |file|
#	  if (file.length > 2)
#	    # do if matcher
#	  end
#	end
#  end
  
  source_folder = ARGV.fetch(0)
  target_folder = ARGV.fetch(1)
	
	# Doing a directory search for header files. 
	# This should be removed once a custom gothic library has been created.
	Dir.foreach(source_folder) do |file|
		if (file.length > 2)
			if (file.match(/.*_intrinsics/))
				if (file.match("goth_intrinsics.h")) # do simple if to exclude some files
				elsif (file.match("dict_intrinsics.h"))
				elsif (file.match("bulk_intrinsics.h"))
				elsif (file.match("console_intrinsics.h"))
				elsif (file.match("gen_intrinsics.h"))
				elsif (file.match("util_intrinsics.h"))
				elsif (file.match("lull_intrinsics.h"))
				elsif (file.match("ps_intrinsics.h"))
				elsif (file.match("d3proc_intrinsics.h"))
				elsif (file.match("pcre_intrinsics.h"))
				elsif (file.match("inter_intrinsics.h"))
				elsif (file.match("mmi_intrinsics.h"))
				elsif (file.match("mmix_intrinsics.h"))
				elsif (file.match("rastcolbase_intrinsics.h"))
				elsif (file.match("rplot_intrinsics.h"))
				elsif (file.match("math_intrinsics.h"))
				elsif (file.match("lut_intrinsics.h"))
				elsif (file.match("lsr_intrinsics.h"))
				elsif (file.match("metaclass_intrinsics.h"))
				elsif (file.match("metax_intrinsics.h"))
				elsif (file.match("main_doc_intrinsics.h"))
				elsif (file.match("tad_intrinsics.h"))
				elsif (file.match("mmi_motif_intrinsics.h"))
				elsif (file.match("win32disp_intrinsics.h")) # really need to refactor this now
				elsif (file.match("xdisp_intrinsics.h"))
				elsif (file.match("f2c_intrinsics.h"))
				else
					fileintrinsics << "#{source_folder}\\#{file}"
				end

			elsif (file.match(/.*_defns/))
		      filedefns << "#{file}"
			else
			  fileothers << "#{file}"
			end
		end
	end
  
  CMock.new(options).setup_mocks(fileintrinsics, filedefns, fileothers, source_folder, target_folder)
  #cm_writer.create_folders(target_folder)

end