# =========================================================================
#   CMock - Automatic Mock Generation for C
#   ThrowTheSwitch.org
#   Copyright (c) 2007-26 Mike Karlesky, Mark VanderVoord, & Greg Williams
#   SPDX-License-Identifier: MIT
# =========================================================================

if $0 == __FILE__

  # make sure there is at least one parameter left (the input file)
  if ARGV.empty?
    puts ["\nusage: ruby #{__FILE__} input_test_file [output_runner] [config.yml]",
          '',
          '  input_test_file         - this is the C file you want to create a runner for',
          '  output_runner           - (optional) the name of the runner file to generate',
          '                            defaults to (input_test_file)_Runner.c',
          '  config.yml              - (optional) a yaml file with configuration.'].join("\n")
    exit 1
  end

  require "#{ENV['UNITY_DIR']}/auto/generate_test_runner"

  test_file = ARGV[0]
  runner_file = ARGV[1] || test_file.sub(/\.c$/, '_Runner.c')
  config_file = ARGV[2]

  # if a config file is provided and exists, use it.
  if config_file && File.exist?(config_file)
    UnityTestRunnerGenerator.new(config_file).run(test_file, runner_file)
  else
    UnityTestRunnerGenerator.new.run(test_file, runner_file)
  end
end
