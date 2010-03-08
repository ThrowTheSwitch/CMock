HERE = File.expand_path(File.dirname(__FILE__)) + '/'

require HERE + 'config/test_environment'
require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rakefile_helper'

include RakefileHelpers

DEFAULT_CONFIG_FILE = 'gcc.yml'

configure_clean
configure_toolchain(DEFAULT_CONFIG_FILE)

task :default => ['test:all']
task :cruise => [:default]

desc "Load configuration"
task :config, :config_file do |t, args|
  args = {:config_file => DEFAULT_CONFIG_FILE} if args[:config_file].nil?
  args = {:config_file => args[:config_file] + '.yml'} unless args[:config_file] =~ /\.yml$/i
  configure_toolchain(args[:config_file])
end

namespace :test do
  desc "Run all unit and system tests"
  task :all => [:clobber, 'test:units', 'test:c', 'test:system']

  desc "Run Unit Tests"
  Rake::TestTask.new('units') do |t|
    t.pattern = 'test/unit/*_test.rb'
    t.verbose = true
  end
  
  #individual unit tests
  FileList['test/unit/*_test.rb'].each do |test|
    Rake::TestTask.new(File.basename(test,'.*')) do |t|
      t.pattern = test
      t.verbose = true
    end
  end
  
  desc "Run C Unit Tests"
  task :c do
    build_and_test_c_files
  end
  
  #get a list of all system tests, removing unsupported tests for this compiler
  sys_unsupported  = $cfg['unsupported'].map {|a| 'test/system/test_interactions/'+a+'.yml'}
  sys_tests_to_run = FileList['test/system/test_interactions/*.yml'] - sys_unsupported
  compile_unsupported  = $cfg['unsupported'].map {|a| SYSTEST_COMPILE_MOCKABLES_PATH+a+'.h'}
  compile_tests_to_run = FileList[SYSTEST_COMPILE_MOCKABLES_PATH + '*.h'] - compile_unsupported
  
  desc "Run System Tests"
  task :system => [:clobber] do
    unless (sys_unsupported.empty? and compile_unsupported.empty?)
      report "\nIgnoring these system tests..."
      sys_unsupported.each {|a| report a}
      compile_unsupported.each {|a| report a}
    end
    report "\nRunning system tests..."
    tests_failed = run_system_test_interactions(sys_tests_to_run)
    raise "System tests failed." if (tests_failed > 0)
    
    run_system_test_compilations(compile_tests_to_run)
  end
  
  #individual system tests
  sys_tests_to_run.each do |test|
    desc "Run system test #{File.basename(test,'.*')}"
    task "test:#{File.basename(test,'.*')}" do
      run_system_test_interactions([test])
    end
  end
  
  desc "Profile Mock Generation"
  task :profile => [:clobber] do
    run_system_test_profiles(FileList[SYSTEST_COMPILE_MOCKABLES_PATH + '*.h'])
  end
  
end