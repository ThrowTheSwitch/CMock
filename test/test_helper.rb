require File.expand_path(File.dirname(__FILE__)) + "/../config/test_environment"

#gem install test-unit -v 1.2.3
ruby_version = RUBY_VERSION.split('.')
if (ruby_version[1].to_i == 9) and (ruby_version[2].to_i > 1)
  require 'gems'
  gem 'test-unit'
end
require 'test/unit'

require 'behaviors'
require 'hardmock'

class Test::Unit::TestCase
  extend Behaviors
  
end
