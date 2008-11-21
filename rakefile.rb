HERE = File.expand_path(File.dirname(__FILE__)) + '/'

require HERE + 'config/environment'
require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rakefile_helper'

include RakefileHelpers

DEFAULT_CONFIG_FILE = 'gcc.yml'

configure_toolchain(DEFAULT_CONFIG_FILE)

task :default => [:clobber, 'test:all', :app]

desc "Build application"
task :app do
  build_application('Main')
end

desc "Load configuration"
task :config, :config_file do |t, args|
  args = {:config_file => DEFAULT_CONFIG_FILE} if args[:config_file].nil?
  args = {:config_file => args[:config_file] + '.yml'} unless args[:config_file] =~ /\.yml$/i
  configure_toolchain(args[:config_file])
end

namespace :test do

  desc "Run CMock and example application tests"
  task :all => [:clean, :units, :example, :app]

  Rake::TestTask.new('units') do |t|
    t.pattern = 'test/unit/*_test.rb'
    t.verbose = true
  end
  
  desc "Run example unit tests"
  task :example => [:clean] do
    systest_test_files = get_unit_test_files
    run_systests(systest_test_files)
    tests_failed = report_summary
    raise "Unit tests failed." if (tests_failed > 0)
  end
  
  get_unit_test_files.each do |test_file|
    file_name = File.basename(test_file)
    module_name = file_name.sub(/Test/,'')
    task file_name do
      run_systests(test_file)
    end
    desc "Test #{module_name}"
    task module_name do
      run_systests(test_file)
    end
  end
  
end