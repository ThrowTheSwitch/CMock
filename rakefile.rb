HERE = File.expand_path(File.dirname(__FILE__)) + '/'

require HERE + 'config/environment'
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

desc "Generate parser(s) from Treetop grammar(s)"
task :treetop do
  require 'rubygems'
  require 'treetop'

  treetop_files = FileList.new('lib/*.treetop')
  compiler = Treetop::Compiler::GrammarCompiler.new

  treetop_files.each do |file|
    compiler.compile(file)
  end
  
  #`vendor/gems/treetop-1.2.5/bin/tt lib/cmock_function_prototype_parser.treetop`
end

namespace :test do

  desc "Run all unit and system tests"
  task :all => ['test:units', 'test:system']

  Rake::TestTask.new('units') do |t|
    t.pattern = 'test/unit/*_test.rb'
    t.verbose = true
  end
  
  desc "Run system tests"
  task :system => [:clobber] do
    report "\nRunning system tests..."

    tests_failed = run_systests(FileList['test/system/cases/*.yml'])
    raise "System tests failed." if (tests_failed > 0)
  end
    
end