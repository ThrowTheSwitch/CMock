# =========================================================================
#   CMock - Automatic Mock Generation for C
#   ThrowTheSwitch.org
#   Copyright (c) 2007-26 Mike Karlesky, Mark VanderVoord, & Greg Williams
#   SPDX-License-Identifier: MIT
# =========================================================================

require 'yaml'
require 'fileutils'
require '../vendor/unity/auto/generate_test_runner'
require '../vendor/unity/auto/unity_test_summary'
require '../vendor/unity/auto/colour_reporter.rb'
require './system/systest_generator'

module RakefileHelpers

  SYSTEST_GENERATED_FILES_PATH   = './system/generated/'
  SYSTEST_BUILD_FILES_PATH       = './system/build/'
  SYSTEST_COMPILE_MOCKABLES_PATH = './system/test_compilation/'
  C_EXTENSION = '.c'
  RESULT_EXTENSION = '.result'

  def load_yaml(yaml_filename)
    yaml_string = File.read(yaml_filename)
    begin
      return YAML.load(yaml_string, aliases: true)
    rescue ArgumentError
      return YAML.load(yaml_string)
    end
  end

  def find_cmock_target(targets_dir, config_file)
    return config_file if File.exist?("#{targets_dir}/#{config_file}")

    basename = File.basename(config_file, '.yml')
    while basename.include?('_')
      basename = basename.rpartition('_').first
      candidate = "#{basename}.yml"
      return candidate if File.exist?("#{targets_dir}/#{candidate}")
    end

    nil
  end

  def load_configuration(config_file)
    $cfg_file = config_file
    $proj = load_yaml('./project.yml')

    unity_target    = "../vendor/unity/test/targets/#{$cfg_file}"
    cmock_targets_dir = './targets'

    if File.exist?(unity_target)
      # Load Unity base target, then CMock overlay (unsupported list, extra defines)
      puts "Loading Unity target:  #{unity_target}"
      $unity_cfg = load_yaml(unity_target)

      cmock_file = find_cmock_target(cmock_targets_dir, $cfg_file)
      if cmock_file
        puts "Loading CMock overlay: #{cmock_targets_dir}/#{cmock_file}"
        $cmock_cfg = load_yaml("#{cmock_targets_dir}/#{cmock_file}")
      else
        puts "No CMock overlay found for #{$cfg_file}"
        $cmock_cfg = {}
      end
    else
      # CMock-only target (no Unity equivalent); it uses Unity format directly
      puts "Loading CMock-only target: #{cmock_targets_dir}/#{$cfg_file}"
      $unity_cfg = load_yaml("#{cmock_targets_dir}/#{$cfg_file}")
      $cmock_cfg = {}
    end

    $colour_output = $proj[:project][:colour]
  end

  def configure_clean
    CLEAN.include($proj[:project][:build_root] + '*.*')
  end

  def configure_toolchain(config_file)
    load_configuration(config_file)
    configure_clean
  end

  def get_local_include_dirs
    $proj[:paths][:include].reject { |dir| dir.is_a?(Array) }
  end

  def extract_headers(filename)
    includes = []
    lines = File.readlines(filename)
    lines.each do |line|
      m = line.match(/^\s*#include\s+\"\s*(.+\.[hH])\s*\"/)
      includes << m[1] unless m.nil?
    end
    includes << File.basename(filename, ".c").slice(5, 256) + "_unity_helper.h"
    return includes
  end

  def find_source_file(header, paths)
    paths.each do |dir|
      src_file = dir + header.ext(C_EXTENSION)
      return src_file if File.exist?(src_file)
    end
    nil
  end

  def tackit(strings)
    case strings
    when Array
      "\"#{strings.join}\""
    when /^-/
      strings
    when /\s/
      "\"#{strings}\""
    else
      strings
    end
  end

  # All defines: project common + Unity target + CMock overlay + any extras
  def all_defines(extra = [])
    (($proj[:defines][:common] || []) +
     ($unity_cfg[:defines][:test] || []) +
     (($cmock_cfg[:defines] || {})[:test] || []) +
     extra).uniq
  end

  # Toolchain-specific include paths: Array items in Unity's :paths: :test:
  # (e.g., IAR compiler include directories encoded as path-concatenation arrays)
  def toolchain_include_paths
    ($unity_cfg[:paths][:test] || []).select { |p| p.is_a?(Array) }
  end

  # Returns the unsupported test list, regardless of whether it came from
  # a CMock overlay or a CMock-only target file.
  def unsupported_tests
    $cmock_cfg[:unsupported] || $unity_cfg[:unsupported] || []
  end

  # Resolve Unity's argument template tokens and produce a flat argument string.
  #   COLLECTION_PATHS_TEST_TOOLCHAIN_INCLUDE  → -I per toolchain path (Arrays from :paths: :test:)
  #   COLLECTION_PATHS_TEST_SUPPORT_SOURCE_INCLUDE_VENDOR → -I per project include path
  #   COLLECTION_DEFINES_TEST_AND_VENDOR       → -D per define
  #   ${1}  → input file(s)
  #   ${2}  → output file
  def build_argument_list(raw_args, toolchain_paths, project_paths, defines, input, output)
    result = []
    raw_args.each do |arg|
      if arg.is_a?(Array)
        result << arg.join
      elsif arg.include?('COLLECTION_PATHS_TEST_TOOLCHAIN_INCLUDE')
        toolchain_paths.each { |p| result << "-I\"#{p.is_a?(Array) ? p.join : p}\"" }
      elsif arg.include?('COLLECTION_PATHS_TEST_SUPPORT_SOURCE_INCLUDE_VENDOR')
        project_paths.each { |p| result << "-I\"#{p}\"" }
      elsif arg.include?('COLLECTION_DEFINES_TEST_AND_VENDOR')
        defines.each { |d| result << "-D#{d}" }
      else
        result << arg.gsub('${1}', input.to_s).gsub('${2}', output.to_s)
      end
    end
    result.join(' ')
  end

  def compile(file, extra_defines = [])
    tool       = $unity_cfg[:tools][:test_compiler]
    ext        = $unity_cfg[:extension][:object]
    build_root = $proj[:project][:build_root]
    obj_file   = build_root + File.basename(file, C_EXTENSION) + ext

    cmd_str = tackit(tool[:executable]) + ' ' +
              build_argument_list(tool[:arguments],
                                  toolchain_include_paths,
                                  $proj[:paths][:include],
                                  all_defines(extra_defines),
                                  file, obj_file)
    execute(cmd_str)
    File.basename(obj_file)
  end

  def link_it(exe_name, obj_list)
    tool       = $unity_cfg[:tools][:test_linker]
    ext        = $unity_cfg[:extension][:executable]
    build_root = $proj[:project][:build_root]

    input_files = obj_list.uniq.map { |obj| build_root + obj }.join(' ')
    output_file = build_root + exe_name + ext

    cmd_str = tackit(tool[:executable]) + ' ' +
              build_argument_list(tool[:arguments], [], [], [], input_files, output_file)
    execute(cmd_str)
  end

  def build_simulator_fields
    return nil unless $unity_cfg[:tools][:test_fixture]
    tool      = $unity_cfg[:tools][:test_fixture]
    executable = tackit(tool[:executable])
    raw_args   = tool[:arguments] || []
    idx        = raw_args.index('${1}')
    if idx
      pre  = raw_args[0...idx].map { |a| a.is_a?(Array) ? a.join : a }.join(' ')
      post = raw_args[(idx + 1)..].map { |a| a.is_a?(Array) ? a.join : a }.join(' ')
    else
      pre  = ''
      post = raw_args.map { |a| a.is_a?(Array) ? a.join : a }.join(' ')
    end
    { command: "#{executable} ", pre_support: pre, post_support: post }
  end

  def execute(command_string, verbose=true, raise_on_failure=true)
    output = `#{command_string}`.chomp
    report(output) if (verbose && !output.nil? && (output.length > 0))
    if ($?.exitstatus != 0) and (raise_on_failure)
      raise "#{command_string} failed. (Returned #{$?.exitstatus})"
    end
    return output
  end

  def run_astyle(style_what)
    report "Styling C Code..."
    command = "AStyle " \
              "--style=allman --indent=spaces=4 --indent-switches --indent-preproc-define --indent-preproc-block " \
              "--pad-oper --pad-comma --unpad-paren --pad-header " \
              "--align-pointer=type --align-reference=name " \
              "--add-brackets --mode=c --suffix=none " \
              "#{style_what}"
    execute(command, false)
    report "Styling C:PASS"
  end

  def report_summary
    summary = UnityTestSummary.new
    summary.root = File.expand_path(File.dirname(__FILE__)) + '/'
    results_glob = "#{$proj[:project][:build_root]}*.test*"
    results_glob.gsub!(/\\/, '/')
    results = Dir[results_glob]
    summary.targets = results
    summary.run
    fail_out "FAIL: There were failures" if (summary.failures > 0)
  end

  def run_system_test_interactions(test_case_files)
    load '../lib/cmock.rb'

    SystemTestGenerator.new.generate_files(test_case_files)
    test_files = FileList.new(SYSTEST_GENERATED_FILES_PATH + 'test*.c')

    load_configuration($cfg_file)

    include_dirs = get_local_include_dirs

    # Build and execute each unit test
    test_files.each do |test|

      obj_list = []

      test_base    = File.basename(test, C_EXTENSION)
      cmock_config = test_base.gsub(/test_/, '') + '_cmock.yml'

      report "Executing system tests in #{File.basename(test)}..."

      # Detect dependencies and build required modules
      extract_headers(test).each do |header|

        # Generate any needed mocks
        if header =~ /^mock_(.*)\.[hH]$/i
          module_name = $1
          cmock = CMock.new(SYSTEST_GENERATED_FILES_PATH + cmock_config)
          cmock.setup_mocks("#{$proj[:paths][:source].first}#{module_name}.h")
        end
        # Compile corresponding source file if it exists
        src_file = find_source_file(header, include_dirs)
        obj_list << compile(src_file) unless src_file.nil?
      end

      # Generate and build the test suite runner
      runner_name = test_base + '_runner.c'
      runner_path = $proj[:paths][:source].first + runner_name
      UnityTestRunnerGenerator.new(SYSTEST_GENERATED_FILES_PATH + cmock_config).run(test, runner_path)
      obj_list << compile(runner_path)

      # Build the test module
      obj_list << compile(test)

      # Link the test executable
      link_it(test_base, obj_list)

      # Execute unit test and generate results file
      simulator  = build_simulator_fields
      ext        = $unity_cfg[:extension][:executable]
      build_root = $proj[:project][:build_root]
      executable = build_root + test_base + ext
      cmd_str = if simulator.nil?
                  executable
                else
                  "#{simulator[:command]} #{simulator[:pre_support]} #{executable} #{simulator[:post_support]}"
                end
      output = execute(cmd_str, false, false)
      test_results = build_root + test_base + RESULT_EXTENSION
      File.open(test_results, 'w') { |f| f.print output }
    end

    # Parse and report test results
    total_tests = 0
    total_failures = 0
    failure_messages = []

    test_case_files.each do |test_case|
      tests = (load_yaml(test_case))[:systest][:tests][:units]
      total_tests += tests.size

      test_file    = 'test_' + File.basename(test_case).ext(C_EXTENSION)
      result_file  = test_file.ext(RESULT_EXTENSION)
      test_results = File.readlines(SYSTEST_BUILD_FILES_PATH + result_file).reject {|line| line.size < 10 }
      tests.each_with_index do |test, index|
        this_failed = case(test[:pass])
          when :ignore
            (test_results[index] =~ /:IGNORE/).nil?
          when true
            (test_results[index] =~ /:PASS/).nil?
          when false
            (test_results[index] =~ /:FAIL/).nil?
        end
        if (this_failed)
          total_failures += 1
          test_results[index] =~ /test#{index+1}:(.+)/
          failure_messages << "#{test_file}:test#{index+1}:should #{test[:should]}:#{$1}"
        end
        if (test[:verify_error]) and not (test_results[index] =~ /test#{index+1}:.*#{test[:verify_error]}/)
          total_failures += 1
          failure_messages << "#{test_file}:test#{index+1}:should #{test[:should]}:should have output matching '#{test[:verify_error]}' but was '#{test_results[index]}'"
        end
      end
    end

    report "\n"
    report "------------------------------------\n"
    report "SYSTEM TEST MOCK INTERACTION SUMMARY\n"
    report "------------------------------------\n"
    report "#{total_tests} Tests #{total_failures} Failures 0 Ignored\n"
    report "\n"

    if (failure_messages.size > 0)
      report 'System test failures:'
      failure_messages.each { |failure| report failure }
    end

    report ''
    return total_failures
  end

  def profile_this(filename)
    profile = true
    begin
      require 'ruby-prof'
      RubyProf.start
    rescue
      profile = false
    end

    yield

    if (profile)
      profile_result = RubyProf.stop
      File.open("Profile_#{filename}.html", 'w') do |f|
        RubyProf::GraphHtmlPrinter.new(profile_result).print(f)
      end
    end
  end

  def run_system_test_compilations(mockables)
    load '../lib/cmock.rb'
    load_configuration($cfg_file)

    report "\n"
    report "------------------------------------\n"
    report "SYSTEM TEST MOCK COMPILATION SUMMARY\n"
    report "------------------------------------\n"
    mockables.each do |header|
      mock_filename = 'mock_' + File.basename(header).ext('.c')
      CMock.new(SYSTEST_COMPILE_MOCKABLES_PATH + 'config.yml').setup_mocks(header)
      report "Compiling #{mock_filename}..."
      compile(SYSTEST_GENERATED_FILES_PATH + mock_filename)
    end
  end

  def run_system_test_profiles(mockables)
    load '../lib/cmock.rb'
    load_configuration($cfg_file)

    report "\n"
    report "--------------------------\n"
    report "SYSTEM TEST MOCK PROFILING\n"
    report "--------------------------\n"
    mockables.each do |header|
      mock_filename = 'mock_' + File.basename(header).ext('.c')
      profile_this(mock_filename.gsub('.c','')) do
        10.times do
          CMock.new(SYSTEST_COMPILE_MOCKABLES_PATH + 'config.yml').setup_mocks(header)
        end
      end
      report "Compiling #{mock_filename}..."
      compile(SYSTEST_GENERATED_FILES_PATH + mock_filename)
    end
  end

  def build_and_test_c_files
    report "\n"
    report "----------------\n"
    report "UNIT TEST C CODE\n"
    report "----------------\n"
    ext        = $unity_cfg[:extension][:executable]
    build_root = $proj[:project][:build_root]
    FileList.new("c/*.yml").each do |yaml_file|
      test = load_yaml(yaml_file)
      report "\nTesting #{yaml_file.sub('.yml','')}"
      report "(#{test[:options].join(', ')})"
      test[:files].each { |f| compile(f, test[:options]) }
      obj_files = test[:files].map { |f| f.gsub!(/.*\//,'').gsub!(C_EXTENSION, $unity_cfg[:extension][:object]) }
      link_it('TestCMockC', obj_files)
      simulator = build_simulator_fields
      executable = build_root + 'TestCMockC' + ext
      if simulator.nil?
        execute(executable)
      else
        execute("#{simulator[:command]} #{simulator[:pre_support]} #{executable} #{simulator[:post_support]}")
      end
    end
  end

  def run_examples(verbose=false, raise_on_failure=true)
    report "\n"
    report "-----------------\n"
    report "VALIDATE EXAMPLES\n"
    report "-----------------\n"
    [ "cd #{File.join("..", "examples", "make_example")} && make clean && make setup && make test",
      "cd #{File.join("..", "examples", "temp_sensor")} && rake ci"
    ].each do |cmd|
      report "Testing '#{cmd}'"
      execute(cmd, verbose, raise_on_failure)
    end
  end

  def fail_out(msg)
    puts msg
    exit(-1)
  end
end
