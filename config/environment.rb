ROOT_PATH = File.expand_path(File.dirname(__FILE__) + "/../")

# Setup our load path:
[ 
  'lib',
].each do |dir|
  $LOAD_PATH.unshift(File.join(ROOT_PATH, dir))
end
