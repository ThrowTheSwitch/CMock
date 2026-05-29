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

  def load_configuration(config_file, cmock_overlay = nil)
    $cfg_file = config_file
    $proj = load_yaml('./project.yml')

    unity_targets_dir = '../vendor/unity/test/targets'
    cmock_targets_dir = './targets'
    config_basename   = File.basename(config_file)
    path_specified    = File.dirname(config_file) != '.'

    # Resolve the target file location:
    #   - path specified → use only that location
    #   - no path → check current directory first, then vendor unity targets
    config_target = if path_specified 
      config_file
    elsif File.exist?("./#{config_file}")
      "./#{config_file}"
    else
      "#{unity_targets_dir}/#{config_file}"
    end

    if File.exist?(config_target)
      # Load Unity base target, then CMock overlay (unsupported list, extra defines)
      puts "Loading Toolchain target:  #{config_target}"
      $unity_cfg = load_yaml(config_target)

      cmock_file = cmock_overlay || find_cmock_target(cmock_targets_dir, config_basename)
      if cmock_file
        puts "Loading Toolchain overlay: #{cmock_targets_dir}/#{cmock_file}"
        $cmock_cfg = load_yaml("#{cmock_targets_dir}/#{cmock_file}")
      else
        puts "No Toolchain overlay found for #{config_file}"
        $cmock_cfg = {}
      end
    else
      raise "Cannot find Config File #{config_target}"
    end

    $colour_output = $proj[:project][:colour]
  end

  def configure_clean
    CLEAN.include($proj[:project][:build_root] + '*.*')
  end

  def configure_toolchain(config_file = DEFAULT_CONFIG_FILE, cmock_overlay = nil)
    config_file = config_file || DEFAULT_CONFIG_FILE
    config_file += '.yml' unless config_file =~ /\.yml$/i
    cmock_overlay += '.yml' if cmock_overlay && cmock_overlay !~ /\.yml$/i
    load_configuration(config_file, cmock_overlay)
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
    (($proj[:defines][:test] || []) +
     ($unity_cfg[:defines][:test] || []) +
     (($cmock_cfg[:defines] || {})[:test] || []) +
     extra).uniq
  end

  # Toolchain-specific include paths: Array items in Unity's :paths: :test:
  # (e.g., IAR compiler include directories encoded as path-concatenation arrays)
  def toolchain_include_paths
    (($unity_cfg[:paths] || {})[:test] || []).select { |p| p.is_a?(Array) }
  end

  # Returns the unsupported test list, regardless of whether it came from
  # a CMock overlay or a CMock-only target file.
  def unsupported_tests
    ($cmock_cfg[:unsupported] || []) | ($unity_cfg[:unsupported] || [])
  end

  # Resolve argument template tokens and produce a flat argument string.
  # Supports Ceedling-style positional tokens and legacy Unity COLLECTION_* tokens.
  #   ${5}  → expands to one arg per include path (toolchain paths + project paths combined)
  #   ${6}  → expands to one arg per define
  #   ${1}  → input file(s)
  #   ${2}  → output file
  #   COLLECTION_PATHS_TEST_TOOLCHAIN_INCLUDE          → (legacy) -I per toolchain path
  #   COLLECTION_PATHS_TEST_SUPPORT_SOURCE_INCLUDE_VENDOR → (legacy) -I per project include path
  #   COLLECTION_DEFINES_TEST_AND_VENDOR               → (legacy) -D per define
  def build_argument_list(raw_args, toolchain_paths, project_paths, defines, input, output)
    result = []
    raw_args.each do |arg|
      if arg.is_a?(Array)
        result << arg.join
      elsif arg.include?('${5}')
        (toolchain_paths + project_paths).each do |p|
          result << arg.gsub('${5}', p.is_a?(Array) ? p.join : p.to_s)
        end
      elsif arg.include?('${6}')
        defines.each { |d| result << arg.gsub('${6}', d) }
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
    ext        = $unity_cfg[:extension][:object] || '.o'
    build_root = $proj[:project][:build_root] || 'build/'
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
    ext        = $unity_cfg[:extension][:executable] || ''
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
    report(command_string) if verbose
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
              "--mode=c --suffix=none " \
              "#{style_what}"
    execute(command, false)
    report "Styling C:PASS"
  end

  def save_test_results(test_base, output)
    build_root = $proj[:project][:build_root]
    test_results = build_root + test_base
    test_results += output.match(/OK\s*$/m) ? '.testpass' : '.testfail'
    File.open(test_results, 'w') { |f| f.print output }
  end

  def collect_test_output(output)
    total_tests    = 0
    total_failures = 0
    total_ignored  = 0
    detail_lines   = []

    output.each_line do |line|
      stripped = line.chomp
      if stripped =~ /(\d+) Tests (\d+) Failures (\d+) Ignored/
        total_tests    += Regexp.last_match(1).to_i
        total_failures += Regexp.last_match(2).to_i
        total_ignored  += Regexp.last_match(3).to_i
      elsif stripped =~ /^[^:]+:[^:]+:\w+(?:\([^)]*\))?:(?:PASS|FAIL|IGNORE)/
        detail_lines << stripped
      end
    end

    synthesized  = detail_lines.join("\n")
    synthesized += "\n" unless detail_lines.empty?
    synthesized += "#{total_tests} Tests #{total_failures} Failures #{total_ignored} Ignored\n"
    synthesized += total_failures > 0 ? "FAILED\n" : "OK\n"
    synthesized
  end

  def run_ruby_unit_tests
    report "\n"
    report "--------------------\n"
    report "RUBY UNIT TEST SUITE\n"
    report "--------------------\n"
    total_runs = total_failures = total_errors = total_skips = 0
    Dir['unit/*_test.rb'].sort.each do |tst|
      report "\nRunning #{tst.to_s}"
      output = execute("ruby -I. #{tst} -v", true, false)
      output.each_line do |line|
        if line =~ /(\d+) runs, \d+ assertions, (\d+) failures, (\d+) errors, (\d+) skips/
          total_runs     += Regexp.last_match(1).to_i
          total_failures += Regexp.last_match(2).to_i
          total_errors   += Regexp.last_match(3).to_i
          total_skips    += Regexp.last_match(4).to_i
        end
      end
    end
    failures = total_failures + total_errors
    result  = "#{total_runs} Tests #{failures} Failures #{total_skips} Ignored\n"
    result += failures > 0 ? "FAILED\n" : "OK\n"
    save_test_results('ruby_unit_tests', result)
    raise "Ruby unit tests failed." if failures > 0
  end

  def report_summary
    summary = UnityTestSummary.new
    summary.root = File.expand_path(File.dirname(__FILE__)) + '/'
    results_glob = "#{$proj[:project][:build_root]}*.test*"
    results_glob.gsub!(/\\/, '/')
    results = Dir[results_glob]
    summary.targets = results
    report summary.run
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
      ext        = $unity_cfg[:extension][:executable] || ''
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

    report "\n\nSystem Testing Results: "
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
          new_msg = "#{test_file}:test#{index+1}:should #{test[:should]}:#{$1}"
          failure_messages << new_msg
          report new_msg
        elsif (test[:verify_error]) and not (test_results[index] =~ /test#{index+1}:.*#{test[:verify_error]}/)
          total_failures += 1
          new_msg = "#{test_file}:test#{index+1}:should #{test[:should]}:should have output matching '#{test[:verify_error]}' but was '#{test_results[index]}'"
          failure_messages << new_msg
          report new_msg
        else
          report "#{test_file}:test#{index+1}:should #{test[:should]}:PASS"
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
    result  = failure_messages.join("\n")
    result += "\n" unless failure_messages.empty?
    result += "#{total_tests} Tests #{total_failures} Failures 0 Ignored\n"
    result += total_failures > 0 ? "FAILED\n" : "OK\n"
    save_test_results('system_interactions', result)
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
    pass_count = 0
    mockables.each do |header|
      mock_filename = 'mock_' + File.basename(header).ext('.c')
      CMock.new(SYSTEST_COMPILE_MOCKABLES_PATH + 'config.yml').setup_mocks(header)
      report "Compiling #{mock_filename}..."
      compile(SYSTEST_GENERATED_FILES_PATH + mock_filename)
      pass_count += 1
    end
    report "#{pass_count} Tests 0 Failures 0 Ignored\nOK\n"
    save_test_results('system_compilations', "#{pass_count} Tests 0 Failures 0 Ignored\nOK\n")
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
    ext        = $unity_cfg[:extension][:executable] || ''
    build_root = $proj[:project][:build_root]
    combined_output = ''
    FileList.new("c/*.yml").each do |yaml_file|
      test = load_yaml(yaml_file)
      report "\nTesting #{yaml_file.sub('.yml','')}"
      report "(#{test[:options].join(', ')})"
      test[:files].each { |f| compile(f, test[:options]) }
      obj_files = test[:files].map { |f| f.gsub!(/.*\//,'').gsub!(C_EXTENSION, $unity_cfg[:extension][:object] || '.o') }
      link_it('TestCMockC', obj_files)
      simulator = build_simulator_fields
      executable = build_root + 'TestCMockC' + ext
      cmd = simulator.nil? ? executable : "#{simulator[:command]} #{simulator[:pre_support]} #{executable} #{simulator[:post_support]}"
      combined_output += execute(cmd, true, false) + "\n"
    end
    result = collect_test_output(combined_output)
    save_test_results('c_unit_tests', result)
    raise "C unit tests failed." if result =~ /FAILED/
  end

  def run_examples()
    report "\n"
    report "-----------------\n"
    report "VALIDATE EXAMPLES\n"
    report "-----------------\n"
    total_tests    = 0
    total_failures = 0
    total_ignored  = 0
    puts "DEBUG DIS #{$cmock_test_config_file}"
    cfg_file = "#{($cmock_test_config_file =~ /[\\\/]/) ? '../' : ''}#{$cmock_test_config_file}" 

    # Determine which examples are valid for this platform
    examples = {
      :make_example => "cd #{File.join("..", "examples", "make_example")} && make clean && make setup && make test",
      :rake_example => "cd #{File.join("..", "examples", "temp_sensor")} && rake config[\"#{cfg_file}\"] ci"
    }
    examples.delete(:make_example) unless ($cmock_test_config_file =~ /gcc/)

    # Run the examples
    examples.each_pair do |key, cmd|
      report "Testing Example: '#{key}'"
      execute(cmd, true, false).each_line do |line|
        if line =~ /(\d+) TOTAL TESTS (\d+) TOTAL FAILURES (\d+) IGNORED/
          total_tests    += Regexp.last_match(1).to_i
          total_failures += Regexp.last_match(2).to_i
          total_ignored  += Regexp.last_match(3).to_i
        end
      end
    end

    # Report the results from the examples
    result  = "#{total_tests} Tests #{total_failures} Failures #{total_ignored} Ignored\n"
    result += total_failures > 0 ? "FAILED\n" : "OK\n"
    save_test_results('examples', result)
    raise "Examples failed." if total_failures > 0
  end

  def fail_out(msg)
    puts msg
    exit(-1)
  end
end
