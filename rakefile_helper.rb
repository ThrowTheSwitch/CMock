
def Kernel.is_windows?
  processor, platform, *rest = RUBY_PLATFORM.split("-")
  platform == 'mswin32'
end

module RakefileConstants

  C_EXTENSION = '.c'
  OBJ_EXTENSION = '.o'
  
  if (Kernel.is_windows?)
    EXE_EXTENSION = '.exe'
  else
    EXE_EXTENSION = '.out'  
  end
  
  UNITY_DIR = 'vendor/unity/src/'

  SYSTEST_BASE = 'test/system/'
  SYSTEST_SOURCE_DIR = SYSTEST_BASE + 'source/'
  SYSTEST_TEST_DIR   = SYSTEST_BASE + 'test/'
  SYSTEST_MOCKS_DIR  = SYSTEST_BASE + 'mocks/'
  SYSTEST_BUILD_DIR  = SYSTEST_BASE + 'build/'

  SYSTEST_INCLUDE_DIRS = [SYSTEST_SOURCE_DIR, SYSTEST_TEST_DIR, SYSTEST_MOCKS_DIR, UNITY_DIR]

end

module RakefileHelpers

  require 'fileutils'

  def extract_headers(filename)
    includes = []
    lines = File.readlines(filename)
    lines.each do |line|
      m = line.match /#include \"(.*)\"/
      if not m.nil?
        includes << m[1]
      end
    end
    return includes
  end

  def find_source_file(header)
    src_file = ''
    SYSTEST_INCLUDE_DIRS.each do |dir|
      src_file = dir + header.ext(C_EXTENSION)
      if (File.exists?(src_file))
        return src_file
      end
    end
    return ''
  end
  
  def compile(config, file)
    cmd_str = 
      "#{config["path"]}#{config["compiler"]} #{config["compile_flags"]} " +
      "-B#{config["path"]} " +
      (SYSTEST_INCLUDE_DIRS.map{|dir|"-I#{dir} "}).join +
      "#{file} " +
      "-o #{SYSTEST_BUILD_DIR}#{File.basename(file, C_EXTENSION)}#{OBJ_EXTENSION}"
    execute(cmd_str)
  end
  
  def link(config, exe_name, obj_list)
    cmd_str = 
      "#{config["path"]}#{config["linker"]} " +
      "-B#{config["path"]} " +
      (obj_list.map{|obj|"#{SYSTEST_BUILD_DIR}#{obj} "}).join +
      "-o #{SYSTEST_BUILD_DIR}#{exe_name}#{EXE_EXTENSION}"
    execute(cmd_str)      
  end
  
  def yaml_read(filename)  
    return YAML.load(File.read(filename))
  end

  def report(message)
    puts message
    $stdout.flush
    $stderr.flush
  end

  def execute(command_string, verbose=true)
    report command_string
    output = `#{command_string}`
    report(output) if verbose
    report ''
    if $?.exitstatus != 0
      raise "Command failed. (Returned #{$?.exitstatus})"
    end
    return output
  end
  
end

