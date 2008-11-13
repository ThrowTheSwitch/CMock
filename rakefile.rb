$here = File.expand_path(File.dirname(__FILE__))

require $here + '/config/environment'
require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rakefile_helper'

include RakefileHelpers

configure_clean

task :default => [ :clobber, 'tests:all', :app ]

desc "Build application"
task :app do
  COMPILER_CONFIGS.each do |cfg_file|
    build_application(yaml_read(cfg_file), 'Main')
  end
end

namespace :tests do

  desc "Run unit and system tests"
  task :all => [:clean, :units, :system, :app]

  Rake::TestTask.new('units') do |t|
    t.pattern = 'test/unit/*_test.rb'
    t.verbose = true
  end
  
  desc "Run system tests"
  task :system => [:clean] do
    COMPILER_CONFIGS.each do |cfg_file|
      config = yaml_read(cfg_file)
      systest_test_files = get_unit_test_files(config)
      run_systests(config, systest_test_files)
      report_summary(config)
    end
  end
  
end