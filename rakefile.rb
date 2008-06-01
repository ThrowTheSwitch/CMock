$here = File.dirname(__FILE__)

require 'rake'
require 'rake/clean'
require 'rake/testtask'

task :default do
  sh 'spec test'
end