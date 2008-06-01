$here = File.dirname(__FILE__)

require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rakefile_helper'

include RakefileConstants
include RakefileHelpers

SYSTEST_TEST_FILES = FileList.new(SYSTEST_TEST_DIR + '*Test' + C_EXTENSION)

COMPILER_CONFIGS = FileList.new('*.yml')

CLEAN.include(SYSTEST_BUILD_DIR + '*.*')
CLEAN.include(SYSTEST_MOCKS_DIR + '*.*')

task :default => [ :clobber, 'tests:all' ]

namespace :tests do

  desc "Run unit and system tests"
  task :all => [ 'units', 'system' ]

  Rake::TestTask.new('units') do |t|
  	t.pattern = 'test//unit/*_test.rb'
  	t.verbose = true
  end
  
  desc "Run system tests"
  task :system do
    COMPILER_CONFIGS.each do |cfg_file|
       run_systests(yaml_read(cfg_file), SYSTEST_TEST_FILES)
    end
  end
  
end



def run_systests(config, test_files)

  test_files.each do |test|
    obj_list = []
    test_base = File.basename(test, C_EXTENSION)
    headers = extract_headers(test)
  
    headers.each do |header|
      compile(config, find_source_file(header))
      obj_list << header.ext(OBJ_EXTENSION)
    end
    
    compile(config, test)
    obj_list << test_base.ext(OBJ_EXTENSION)
    
    link(config, test_base, obj_list)
    
    execute(SYSTEST_BUILD_DIR + test_base + EXE_EXTENSION)
  end

end

