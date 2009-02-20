class CMockUnityHelperParser
  
  attr_accessor :c_types
  
  def initialize(config)
    @config = config
    @c_types = map_C_types(config.treat_as).merge(import_source(config.load_unity_helper))
  end

  def get_helper(ctype)
    lookup = ctype.gsub(/const\s+/,'').strip.gsub(/\s+/,'_')#.gsub(/\*$/,'_ARRAY')
    return @c_types[lookup] if (@c_types[lookup])
    raise("Don't know how to test #{ctype} and memory tests are disabled!") unless @config.memcpy_if_unknown
    return 'TEST_ASSERT_EQUAL_MEMORY_MESSAGE'
  end
  
  private ###########################
  
  def map_C_types(treat_as={})
    c_types = {}
    treat_as.each_pair do |expect, ctypes|
      ctypes.each {|ctype| c_types[ctype] = "TEST_ASSERT_EQUAL_#{expect}_MESSAGE"}
    end
    c_types
  end
  
  def import_source(source=nil)
    return {} if source.nil?
    
    c_types = {}
    source = source.gsub(/\/\/.*$/, '') #remove line comments
    source = source.gsub(/\/\*.*?\*\//m, '') #remove block comments
     
    #scan for comparison helpers
    m = Regexp.new('^\s*#define\s+(TEST_ASSERT_EQUAL_(\w+)_MESSAGE|TEST_ASSERT_EQUAL_(\w+))\s*\(' + Array.new(2,'\s*\w+\s*').join(',') + '\)')
    a = source.scan(m).flatten.compact
    a.each_slice(2) {|expect, ctype| c_types[ctype] = expect unless expect.include?("_ARRAY")}
      
    #scan for array variants of those helpers
    m = Regexp.new('^\s*#define\s+(TEST_ASSERT_EQUAL_(\w+_ARRAY)_MESSAGE|TEST_ASSERT_EQUAL_(\w+_ARRAY))\s*\(' + Array.new(3,'\s*\w+\s*').join(',') + '\)')
    a = source.scan(m).flatten.compact
    a.each_slice(2) {|expect, ctype| c_types[ctype.gsub('_ARRAY','*')] = expect}
    
    c_types
  end
end
