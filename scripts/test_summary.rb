require 'cmock'
require 'fileutils'
require "#{ENV['UNITY_DIR']}/auto/unity_test_summary.rb"

build_dir = ENV.fetch('BUILD_DIR', './build')
test_build_dir = ENV.fetch('TEST_BUILD_DIR', File.join(build_dir, 'test'))

parser = UnityTestSummary.new
results = Dir["#{test_build_dir}/*.result"]
parser.set_targets(results)
parser.run
puts parser.report
exit(parser.failures)
