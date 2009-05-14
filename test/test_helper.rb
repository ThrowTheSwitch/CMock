require File.expand_path(File.dirname(__FILE__)) + "/../config/test_environment"
require 'test/unit'
require 'behaviors'
require 'hardmock'

class Test::Unit::TestCase
  extend Behaviors
  
end
