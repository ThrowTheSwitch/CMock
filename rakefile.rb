$here = File.expand_path(File.dirname(__FILE__))

require $here + '/config/environment'
require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rakefile_helper'

include RakefileHelpers

load_configuration('gcc.yml') # Uncomment this line to enable GCC
#load_configuration('iar.yml') # Uncomment this line to enable IAR Embedded Workbench
configure_clean

task :default => [ :clobber, 'test:all', :app ]

desc "Build application"
task :app do
  build_application('Main')
end

namespace :test do

  desc "Run unit and system tests"
  task :all => [:clean, :units, :system, :app]

  Rake::TestTask.new('units') do |t|
    t.pattern = 'test/unit/*_test.rb'
    t.verbose = true
  end
  
  desc "Run system tests"
  task :system => [:clean] do
    systest_test_files = get_unit_test_files
    run_systests(systest_test_files)
    report_summary
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