$here = File.dirname(__FILE__)

require 'rake'
require 'rake/clean'
require 'rake/testtask'

CLEAN.include('test/system/build/' + '*.*')

task :default => [ :clobber, 'tests:all' ]

namespace :tests do

  desc "Run unit and system tests"
  task :all => [ 'units', 'system' ]

  Rake::TestTask.new('units') do |t|
  	t.pattern = 'test//unit/*_test.rb'
  	t.verbose = true
  end
  
  Rake::TestTask.new('system') do |t|
  	t.pattern = 'test//system/*_test.rb'
  	t.verbose = true
  end

end


