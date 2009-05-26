require 'yaml'
require 'fileutils'
require 'generate_test_runner'
require 'unity_test_summary'
require 'systest_generator'

module RakefileHelpers

  SYSTEST_GENERATED_FILES_PATH   = 'test/system/generated/'
  SYSTEST_BUILD_FILES_PATH       = 'test/system/build/'
  SYSTEST_COMPILE_MOCKABLES_PATH = 'test/system/test_compilation/'

  C_EXTENSION = '.c'
  RESULT_EXTENSION = '.result'
  
  def report(message)
    puts message
    $stdout.flush
    $stderr.flush
  end
  
  def load_configuration(config_file)
    $cfg_file = config_file
    $cfg = YAML.load(File.read($cfg_file))
  end
  
  def configure_clean
    CLEAN.include(SYSTEST_GENERATED_FILES_PATH + '*.*')
    CLEAN.include(SYSTEST_BUILD_FILES_PATH + '*.*')
  end
  
  def configure_toolchain(config_file)
    load_configuration(config_file)
    configure_clean
  end
  
  def get_local_include_dirs
    include_dirs = $cfg['compiler']['includes']['items'].dup
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

  def build_compiler_fields
    command  = tackit($cfg['compiler']['path'])
    if $cfg['compiler']['defines']['items'].nil?
      defines  = ''
    else
      defines  = squash($cfg['compiler']['defines']['prefix'], $cfg['compiler']['defines']['items'])
    end
    options  = squash('', $cfg['compiler']['options'])
    includes = squash($cfg['compiler']['includes']['prefix'], $cfg['compiler']['includes']['items'])
    includes = includes.gsub(/\\ /, ' ').gsub(/\\\"/, '"').gsub(/\\$/, '') # Remove trailing slashes (for IAR)
    return {:command => command, :defines => defines, :options => options, :includes => includes}
  end

  def compile(file, defines=[])
    compiler = build_compiler_fields
    cmd_str = "#{compiler[:command]}#{compiler[:defines]}#{compiler[:options]}#{compiler[:includes]} #{file} " +
      "#{$cfg['compiler']['object_files']['prefix']}#{$cfg['compiler']['object_files']['destination']}" +
      "#{File.basename(file, C_EXTENSION)}#{$cfg['compiler']['object_files']['extension']}"
    execute(cmd_str)
  end
  
  def build_linker_fields
    command  = tackit($cfg['linker']['path'])
    if $cfg['linker']['options'].nil?
      options  = ''
    else
      options  = squash('', $cfg['linker']['options'])
    end
    if ($cfg['linker']['includes'].nil? || $cfg['linker']['includes']['items'].nil?)
      includes = ''
    else
      includes = squash($cfg['linker']['includes']['prefix'], $cfg['linker']['includes']['items'])
    end
    includes = includes.gsub(/\\ /, ' ').gsub(/\\\"/, '"').gsub(/\\$/, '') # Remove trailing slashes (for IAR)
    return {:command => command, :options => options, :includes => includes}
  end
  
  def link(exe_name, obj_list)
    linker = build_linker_fields
    cmd_str = "#{linker[:command]}#{linker[:options]}#{linker[:includes]} " +
      (obj_list.map{|obj|"#{$cfg['linker']['object_files']['path']}#{obj} "}).join +
      $cfg['linker']['bin_files']['prefix'] + ' ' +
      $cfg['linker']['bin_files']['destination'] +
      exe_name + $cfg['linker']['bin_files']['extension']
    execute(cmd_str)
  end
  
  def build_simulator_fields
    return nil if $cfg['simulator'].nil?
    if $cfg['simulator']['path'].nil?
      command = ''
    else
      command = (tackit($cfg['simulator']['path']) + ' ')
    end
    if $cfg['simulator']['pre_support'].nil?
      pre_support = ''
    else
      pre_support = squash('', $cfg['simulator']['pre_support'])
    end
    if $cfg['simulator']['post_support'].nil?
      post_support = ''
    else
      post_support = squash('', $cfg['simulator']['post_support'])
    end
    return {:command => command, :pre_support => pre_support, :post_support => post_support}
  end
  
  def execute(command_string, verbose=true)
    output = `#{command_string}`.chomp
    report(output) if (verbose && !output.nil? && (output.length > 0))
    if $?.exitstatus != 0
      raise "#{command_string} failed. (Returned #{$?.exitstatus})"
    end
    return output
  end
  
  def report_summary
    summary = UnityTestSummary.new
    summary.set_root_path(HERE)
    results_glob = "#{$cfg['compiler']['build_path']}*.test*"
    results_glob.gsub!(/\\/, '/')
    results = Dir[results_glob]
    summary.set_targets(results)
    summary.run
  end
  
  def run_system_test_interactions(test_case_files)
    require 'cmock'
    
    SystemTestGenerator.new.generate_files(test_case_files)
    test_files = FileList.new(SYSTEST_GENERATED_FILES_PATH + 'test*.c')
    
    load_configuration($cfg_file)
    $cfg['compiler']['defines']['items'] = [] if $cfg['compiler']['defines']['items'].nil?
    
    include_dirs = get_local_include_dirs

    # Build and execute each unit test
    test_files.each do |test|

      obj_list = []
      
      test_base    = File.basename(test, C_EXTENSION)
      cmock_config = test_base.gsub(/test_/, '') + '_cmock.yml'
      
      puts "Executing system test cases contained in #{File.basename(test)}..."
      
      # Detect dependencies and build required required modules
      extract_headers(test).each do |header|

        # Generate any needed mocks
        if header =~ /^mock_(.*)\.h/i
          module_name = $1
          cmock = CMock.new(SYSTEST_GENERATED_FILES_PATH + cmock_config)
          cmock.setup_mocks("#{$cfg['compiler']['source_path']}#{module_name}.h")
        end
        # Compile corresponding source file if it exists
        src_file = find_source_file(header, include_dirs)
        if !src_file.nil?
          compile(src_file)
          obj_list << header.ext($cfg['compiler']['object_files']['extension'])
        end
      end

      # Generate and build the test suite runner
      runner_name = test_base + '_runner.c'
      runner_path = $cfg['compiler']['source_path'] + runner_name
      test_gen = UnityTestRunnerGenerator.new
      test_gen.run(test, runner_path, [])
      compile(runner_path)
      obj_list << runner_name.ext($cfg['compiler']['object_files']['extension'])
      
      # Build the test module
      compile(test)
      obj_list << test_base.ext($cfg['compiler']['object_files']['extension'])
      
      # Link the test executable
      link(test_base, obj_list)
      
      # Execute unit test and generate results file
      simulator = build_simulator_fields
      executable = $cfg['linker']['bin_files']['destination'] + test_base + $cfg['linker']['bin_files']['extension']
      if simulator.nil?
        cmd_str = executable
      else
        cmd_str = "#{simulator[:command]} #{simulator[:pre_support]} #{executable} #{simulator[:post_support]}"
      end
      output = execute(cmd_str, false)
      test_results = $cfg['compiler']['build_path'] + test_base + RESULT_EXTENSION
      File.open(test_results, 'w') { |f| f.print output }
    end
    
    # Parse and report test results
    total_tests = 0
    total_failures = 0
    failure_messages = []

    test_case_files.each do |test_case|      
      tests = (YAML.load_file(test_case))[:systest][:tests][:units]
      total_tests += tests.size

      test_file    = 'test_' + File.basename(test_case).ext(C_EXTENSION)
      result_file  = test_file.ext(RESULT_EXTENSION)
      test_results = File.read(SYSTEST_BUILD_FILES_PATH + result_file)

      tests.each_with_index do |test, index|
        # compare test's intended pass/fail state with pass/fail state in actual results;
        # if they don't match, the system test has failed
        if (test[:pass] != !((test_results =~ /test#{index+1}::: PASS/).nil?))
          total_failures += 1
          test_results =~ /test#{index+1}:(.+)/
          failure_messages << "#{test_file}:test#{index+1}:should #{test[:should]}:#{$1}"
        end
      end
    end
    
    puts "\n"
    puts "------------------------------------\n"
    puts "SYSTEM TEST MOCK INTERACTION SUMMARY\n"
    puts "------------------------------------\n"
    puts "TOTAL TESTS: #{total_tests} TOTAL FAILURES: #{total_failures}\n"
    puts "\n"
    
    if (failure_messages.size > 0)
      puts 'System test failures:'
      failure_messages.each do |failure|
        puts failure
      end
    end
    
    puts ''

    return total_failures
  end
  
  def run_system_test_compilations(mockables)
    require 'cmock'
    
    load_configuration($cfg_file)
    $cfg['compiler']['defines']['items'] = [] if $cfg['compiler']['defines']['items'].nil?

    puts "\n"
    puts "------------------------------------\n"
    puts "SYSTEM TEST MOCK COMPILATION SUMMARY\n"
    puts "------------------------------------\n"
    mockables.each do |header|
      cmock = CMock.new(SYSTEST_COMPILE_MOCKABLES_PATH + 'config.yml')
      cmock.setup_mocks(header)
      compile(SYSTEST_GENERATED_FILES_PATH + 'mock_' + File.basename(header).ext('.c'))
    end
  end
  
end

