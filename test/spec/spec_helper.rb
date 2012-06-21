require 'rubygems'

proj_root = File.expand_path(File.dirname(__FILE__) + '/../..')
# require proj_root + '/config/environment'
$LOAD_PATH << proj_root + '/lib'

require 'rspec'
require 'rr'

RSpec.configure do |config|
  config.mock_with :rr
end