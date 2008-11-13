require 'yaml'
require 'fileutils'
require 'cmock'
require 'generate_test_runner'
require 'unity_test_summary'

module RakefileHelpers
  
  # Configure constants appropriately
  C_EXTENSION = '.c'
  processor, platform, *rest = RUBY_PLATFORM.split("-")
  if (platform == 'mswin32')
    EXE_EXTENSION = '.exe'
  else
    EXE_EXTENSION = '.out'  
  end
  COMPILER_CONFIGS = FileList.new('*.yml')
  
  def yaml_read(filename)  
    return YAML.load(File.read(filename))
  end

  def report(message)
    puts message
    $stdout.flush
    $stderr.flush
  end
  
  def configure_clean
    COMPILER_CONFIGS.each do |f|
      config = yaml_read(f)
      CLEAN.include(config['compiler']['mocks_path'] + '*.*') unless config['compiler']['mocks_path'].nil?
      CLEAN.include(config['compiler']['build_path'] + '*.*') unless config['compiler']['mocks_path'].nil?
    end
  end
  
  def get_unit_test_files(config)
    path = config['compiler']['unit_tests_path'] + 'Test*' + C_EXTENSION
    path.gsub!(/\\/, '/')
    FileList.new(path)
  end
  
  def get_local_include_dirs(config)
    include_dirs = config['compiler']['includes']['items'].dup
    include_dirs.delete_if {|dir| dir.is_a?(Array)}
    return include_dirs
  end

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

  def find_source_file(header, paths)
    paths.each do |dir|
      src_file = dir + header.ext(C_EXTENSION)
      if (File.exists?(src_file))
        return src_file
      end
    end
    return nil
  end
  
  def tackit(strings)
    if strings.is_a?(Array)
      result = "\"#{strings.join}\""
    else
      result = strings
    end
    return result
  end

  def squash(prefix, items)
    result = ''
    items.each { |item| result += " #{prefix}#{tackit(item)}" }
    return result
  end

  def build_compiler_fields(config)
    command  = tackit(config['compiler']['path'])
    defines  = ''
    defines  = squash(config['compiler']['defines']['prefix'],
                      config['compiler']['defines']['items']) unless config['compiler']['defines']['items'].nil?
    options  = squash('', config['compiler']['options'])
    includes = squash(config['compiler']['includes']['prefix'], config['compiler']['includes']['items'])
    includes = includes.gsub(/\\ /, ' ').gsub(/\\\"/, '"').gsub(/\\$/, '') # Remove trailing slashes (for IAR)
    return {:command => command, :defines => defines, :options => options, :includes => includes}
  end
  
  def compile(config, file, defines=[])
    
    compiler = build_compiler_fields(config)
    
    ##################################################
    # NEED TO FIGURE OUT WHAT TO DO WITH THIS!!!
    # if !config["path"].nil?
      # cmd_str += "-B#{config["path"]} "
    # end
    ##################################################
    
    cmd_str = "#{compiler[:command]}#{compiler[:defines]}#{compiler[:options]}#{compiler[:includes]} #{file} " +
      "#{config['compiler']['object_files']['prefix']}#{config['compiler']['object_files']['destination']}" +
      "#{File.basename(file, C_EXTENSION)}#{config['compiler']['object_files']['extension']}"
      
    execute(cmd_str)
  end
  
  def build_linker_fields(config)
    command  = tackit(config['linker']['path'])
    options  = ''
    options  += squash('', config['linker']['options']) unless config['linker']['options'].nil?
    includes = ''
    includes += squash(config['linker']['includes']['prefix'],
                       config['linker']['includes']['items']) unless config['linker']['includes']['items'].nil?
    includes = includes.gsub(/\\ /, ' ').gsub(/\\\"/, '"').gsub(/\\$/, '') # Remove trailing slashes (for IAR)
    return {:command => command, :options => options, :includes => includes}
  end
  
  def link(config, exe_name, obj_list)
    linker = build_linker_fields(config)
    cmd_str = "#{linker[:command]}#{linker[:options]}#{linker[:includes]} " +
      (obj_list.map{|obj|"#{config['linker']['object_files']['path']}#{obj} "}).join +
      "#{config['linker']['bin_files']['prefix']} #{config['linker']['bin_files']['destination']}#{exe_name}#{config['linker']['bin_files']['extension']}"
    execute(cmd_str)      
  end
  
  def build_simulator_fields(config)
    return nil if config['simulator'].nil?
    command = ''
    command += (tackit(config['simulator']['path']) + ' ') unless config['simulator']['path'].nil?
    pre_support = ''
    pre_support = squash('', config['simulator']['pre_support']) unless config['simulator']['pre_support'].nil?
    post_support = ''
    post_support = squash('', config['simulator']['post_support']) unless config['simulator']['post_support'].nil?
    return {:command => command, :pre_support => pre_support, :post_support => post_support}
  end

  def execute(command_string, verbose=true)
    report command_string
    output = `#{command_string}`.chomp
    report(output) if (verbose && !output.nil? && (output.length > 0))
    if $?.exitstatus != 0
      raise "Command failed. (Returned #{$?.exitstatus})"
    end
    return output
  end
  
  def report_summary(config)
    summary = UnityTestSummary.new
    summary.set_root_path($here)
    summary.set_targets(Dir["#{config['compiler']['build_path']}*.test*"])
    summary.run
  end
  
  def run_systests(config, test_files)
    
    puts 'Running system tests...'
    
    test_defines = ['TEST']
    my_config = config.dup
    my_config['compiler']['defines']['items'] = [] if my_config['compiler']['defines']['items'].nil?
    my_config['compiler']['defines']['items'] << 'TEST'
    
    include_dirs = get_local_include_dirs(my_config)
    
    test_files.each do |test|
      obj_list = []
      test_base = File.basename(test, C_EXTENSION)
      headers = extract_headers(test)
    
      headers.each do |header|
        if header =~ /^Mock(.*)\.h/i
          module_name = $1
          report "Generating mock for module #{module_name}..."
          cmock = CMock.new(config['compiler']['mocks_path'], ['Types.h'])
          cmock.setup_mocks("#{config['compiler']['source_path']}#{module_name}.h")
        end
      
        src_file = find_source_file(header, include_dirs)
        if !src_file.nil?
          compile(config, src_file, test_defines)
          obj_list << header.ext(config['compiler']['object_files']['extension'])
        end
      end
      
      # Generate and build the test runner
      runner_name = test_base + '_Runner.c'
      runner_path = config['compiler']['build_path'] + runner_name
      test_gen = UnityTestRunnerGenerator.new
      test_gen.run(test, runner_path, ['Types'])
      compile(config, runner_path, test_defines)
      obj_list << runner_name.ext(config['compiler']['object_files']['extension'])
      
      # Build the test file
      compile(config, test, test_defines)
      obj_list << test_base.ext(config['compiler']['object_files']['extension'])
      
      # Link the test executable
      link(config, test_base, obj_list)
      
      # Run test and generate results file
      simulator = build_simulator_fields(config)
      executable = config['linker']['bin_files']['destination'] + test_base + config['linker']['bin_files']['extension']
      if simulator.nil?
        cmd_str = executable
      else
        cmd_str = "#{simulator[:command]} #{simulator[:pre_support]} #{executable} #{simulator[:post_support]}"
      end
      output = execute(cmd_str)
      test_results = config['compiler']['build_path'] + test_base
      if output.match(/OK$/m).nil?
        test_results += '.testfail'
      else
        test_results += '.testpass'
      end
      File.open(test_results, 'w') { |f| f.print output }
      
    end
  end
  
  def build_application(config, main)
  
    puts "Building application..."
  
    obj_list = []
    main_path = config['compiler']['source_path'] + main + C_EXTENSION
    executable_path = config['linker']['bin_files']['destination'] + main + config['linker']['bin_files']['extension']
    main_base = File.basename(main_path, C_EXTENSION)
    headers = extract_headers(main_path)
    include_dirs = get_local_include_dirs(config)
  
    headers.each do |header|
      src_file = find_source_file(header, include_dirs)
      if !src_file.nil?
        compile(config, src_file)
        obj_list << header.ext(config['compiler']['object_files']['extension'])
      end
    end
    
    compile(config, main_path)
    obj_list << main_base.ext(config['compiler']['object_files']['extension'])
    
    link(config, main_base, obj_list)
  end
  
end

