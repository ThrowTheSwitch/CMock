
# Setup our load path:
[ 
  'lib',
  'vendor/behaviors/lib',
  'vendor/hardmock/lib',
  'vendor/unity/auto/',
  'vendor/gems/polyglot-0.2.5/lib/',
  'vendor/gems/treetop-1.2.5/lib/',
  'test/system/'
].each do |dir|
  $LOAD_PATH.unshift( File.join( File.expand_path(File.dirname(__FILE__) + "/../"), dir) )
end
