# =========================================================================
#   CMock - Automatic Mock Generation for C
#   ThrowTheSwitch.org
#   Copyright (c) 2007-26 Mike Karlesky, Mark VanderVoord, & Greg Williams
#   SPDX-License-Identifier: MIT
# =========================================================================

require 'yaml'
require 'fileutils'
require '../../vendor/unity/auto/unity_test_summary'
require '../../vendor/unity/auto/generate_test_runner'
require '../../vendor/unity/auto/colour_reporter'

module RakefileHelpers
  $return_error_on_failures = false

  C_EXTENSION = '.c'.freeze

  def load_yaml(yaml_string)
    YAML.load(yaml_string, aliases: true)
  rescue ArgumentError
    YAML.load(yaml_string)
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
    $proj = load_yaml(File.read('./project.yml'))

    unity_targets_dir = '../../vendor/unity/test/targets'
    cmock_targets_dir = '../../test/targets'
    config_basename   = File.basename(config_file)
    path_specified    = File.dirname(config_file) != '.'

    # Resolve the target file location:
    #   - path specified → use only that location
    #   - no path → check current directory first, then vendor unity targets
    unity_target = if path_specified
                     config_file
                   elsif File.exist?("./#{config_file}")
                     "./#{config_file}"
                   else
                     "#{unity_targets_dir}/#{config_file}"
                   end

    if File.exist?(unity_target)
      puts "Loading Unity target:  #{unity_target}"
      $unity_cfg = load_yaml(File.read(unity_target))

      cmock_file = cmock_overlay || find_cmock_target(cmock_targets_dir, config_basename)
      if cmock_file
        puts "Loading CMock overlay: #{cmock_targets_dir}/#{cmock_file}"
        $cmock_cfg = load_yaml(File.read("#{cmock_targets_dir}/#{cmock_file}"))
      else
        puts "No CMock overlay found for #{config_file}"
        $cmock_cfg = {}
      end
    else
      # CMock-only target (no Unity equivalent); it uses Unity format directly
      puts "Loading CMock-only target: #{cmock_targets_dir}/#{config_basename}"
      $unity_cfg = load_yaml(File.read("#{cmock_targets_dir}/#{config_basename}"))
      $cmock_cfg = {}
    end

    $colour_output = $proj[:project][:colour]
  end

  def configure_clean
    CLEAN.include("#{$proj[:project][:build_root]}*.*")
  end

  def configure_toolchain(config_file = DEFAULT_CONFIG_FILE, cmock_overlay = nil)
    config_file ||= DEFAULT_CONFIG_FILE
    config_file += '.yml' unless config_file =~ /\.yml$/i
    cmock_overlay += '.yml' if cmock_overlay && cmock_overlay !~ /\.yml$/i
    load_configuration(config_file, cmock_overlay)
    configure_clean
  end

  def unit_test_files
    path = $proj[:paths][:test] + "Test*#{C_EXTENSION}"
    path.tr!('\\', '/')
    FileList.new(path)
  end

  def local_include_dirs
    $proj[:paths][:include].reject { |dir| dir.is_a?(Array) }
  end

  def extract_headers(filename)
    includes = []
    lines = File.readlines(filename)
    lines.each do |line|
      m = line.match(/^\s*#include\s+"\s*(.+\.[hH])\s*"/)
      includes << m[1] unless m.nil?
    end
    includes
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
  def toolchain_include_paths
    if $unity_cfg[:paths] && $unity_cfg[:paths][:test]
      $unity_cfg[:paths][:test]
    else
      []
    end
  end

  # Resolve argument template tokens into a flat argument string.
  # Supports Ceedling-style positional tokens and legacy Unity COLLECTION_* tokens.
  #   ${5}  → expands to one arg per include path (toolchain paths + project paths combined)
  #   ${6}  → expands to one arg per define
  #   ${1}  → input file(s)
  #   ${2}  → output file
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
    ext        = $unity_cfg[:extension][:object]
    build_root = $proj[:project][:build_root]
    obj_file   = build_root + File.basename(file, C_EXTENSION) + ext

    cmd_str = "#{tackit(tool[:executable])} #{
              build_argument_list(tool[:arguments],
                                  toolchain_include_paths,
                                  $proj[:paths][:include],
                                  all_defines(extra_defines),
                                  file, obj_file)}"
    execute(cmd_str)
    File.basename(obj_file)
  end

  def link_it(exe_name, obj_list)
    tool       = $unity_cfg[:tools][:test_linker]
    ext        = $unity_cfg[:extension][:executable]
    build_root = $proj[:project][:build_root]

    input_files = obj_list.uniq.map { |obj| build_root + obj }.join(' ')
    output_file = build_root + exe_name + ext

    cmd_str = "#{tackit(tool[:executable])} #{build_argument_list(tool[:arguments], [], [], [], input_files, output_file)}"
    execute(cmd_str)
  end

  def build_simulator_fields
    return nil unless $unity_cfg[:tools][:test_fixture]

    tool       = $unity_cfg[:tools][:test_fixture]
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

  def execute(command_string, verbose = true, ok_to_fail = false)
    report command_string
    output = `#{command_string}`.chomp
    report(output) if verbose && !output.nil? && !output.empty?
    unless (!$?.nil? && $?.exitstatus.zero?) || ok_to_fail
      raise "Command failed. (Returned #{$?.exitstatus})"
    end

    output
  end

  def report_summary
    summary = UnityTestSummary.new
    summary.root = HERE
    results_glob = "#{$proj[:project][:build_root]}*.test*"
    results_glob.tr!('\\', '/')
    results = Dir[results_glob]
    summary.targets = results
    report summary.run
    raise 'There were failures' if (summary.failures > 0) && $return_error_on_failures
  end

  def run_tests(test_files)
    report 'Running system tests...'

    load_configuration($cfg_file)

    include_dirs = local_include_dirs

    # Build and execute each unit test
    test_files.each do |test|
      # Detect dependencies and build required modules
      header_list = (extract_headers(test) + ['cmock.h'] + [($proj[:cmock] || {})[:unity_helper_path]]).compact.uniq
      header_list.each do |header|
        # create mocks if needed
        next unless header =~ /Mock/

        require '../../lib/cmock'
        @cmock ||= CMock.new($proj[:cmock])
        @cmock.setup_mocks([$proj[:paths][:source].first + header.gsub('Mock', '')])
      end

      # compile all mocks and dependencies
      obj_list = []
      header_list.each do |header|
        src_file = find_source_file(header, include_dirs)
        obj_list << compile(src_file, ['TEST']) unless src_file.nil?
      end

      # Build the test runner
      test_base   = File.basename(test, C_EXTENSION)
      runner_name = "#{test_base}_Runner.c"
      runner_path = "#{$proj[:project][:build_root]}#{runner_name}"
      UnityTestRunnerGenerator.new({}).run(test, runner_path)

      obj_list << compile(runner_path, ['TEST'])

      # Build the test module
      obj_list << compile(test, ['TEST'])

      # Link the test executable
      link_it(test_base, obj_list)

      # Execute unit test and generate results file
      simulator  = build_simulator_fields
      build_root = $proj[:project][:build_root]
      executable = build_root + test_base + $unity_cfg[:extension][:executable]
      cmd_str = if simulator.nil?
                  executable
                else
                  "#{simulator[:command]} #{simulator[:pre_support]} #{executable} #{simulator[:post_support]}"
                end
      output = execute(cmd_str, true)
      test_results = build_root + test_base
      test_results += output.match(/OK$/m).nil? ? '.testfail' : '.testpass'
      File.open(test_results, 'w') { |f| f.print output }
    end
  end

  def build_application(main)
    report 'Building application...'

    obj_list = []
    load_configuration($cfg_file)
    main_path = $proj[:paths][:source].first + main + C_EXTENSION

    # Detect dependencies and build required modules
    include_dirs = local_include_dirs
    extract_headers(main_path).each do |header|
      src_file = find_source_file(header, include_dirs)
      obj_list << compile(src_file) unless src_file.nil?
    end

    # Build the main source file
    obj_list << compile(main_path)

    # Create the executable
    link_it(File.basename(main_path, C_EXTENSION), obj_list)
  end
end
