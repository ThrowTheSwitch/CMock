
# Setup our load path:
[ 
  'lib',
  'vendor/behaviors/lib',
  'vendor/hardmock/lib',
  'vendor/unity/auto/',
  'test/system/'
].each do |dir|
  $LOAD_PATH.unshift( File.join( File.expand_path(File.dirname(__FILE__) + "/../"), dir) )
end
