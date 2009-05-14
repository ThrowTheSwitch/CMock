ROOT_PATH = File.expand_path(File.dirname(__FILE__) + "/../")

# Setup our load path:
[ 
  'lib',
  'vendor/gems/polyglot-0.2.5/lib/',
  'vendor/gems/treetop-1.2.5/lib/',
].each do |dir|
  $LOAD_PATH.unshift(File.join(ROOT_PATH, dir))
end

require 'rubygems'
require 'treetop'

