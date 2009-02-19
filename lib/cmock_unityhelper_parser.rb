class CMockUnityHelperParser
  
  attr_accessor :c_types
  
  def initialize(config)
    @c_types = map_C_types(config.treat_as).merge(import_source(config.load_unity_helper))
  end

  def get_helper(ctype)
    lookup = ctype.gsub('const','').strip.gsub(/\s+/,'_')
    return @c_types[lookup] if (@c_types[lookup])
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
    
    a = []
    source = source.gsub(/\/\/.*$/, '') #remove line comments
    source = source.gsub(/\/\*.*?\*\//m, '') #remove block comments
    
    #scan for comparison helpers
    m = Regexp.new('^\s*#define\s+(TEST_ASSERT_EQUAL_(\w+)_MESSAGE|TEST_ASSERT_EQUAL_(\w+))\s*\(' + Array.new(2,'\s*\w+\s*').join(',') + '\)')
    a += source.scan(m).flatten.compact.reject {|helper| helper.include? "_ARRAY"}
    
    #scan for array variants of those helpers
    m = Regexp.new('^\s*#define\s+(TEST_ASSERT_EQUAL_(\w+)_ARRAY_MESSAGE|TEST_ASSERT_EQUAL_(\w+)_ARRAY)\s*\(' + Array.new(3,'\s*\w+\s*').join(',') + '\)')
    a += source.scan(m).flatten.compact

    #add to c_types
    c_types = {}
    a.each_slice(2) {|expect, ctype| c_types[ctype] = expect}
    c_types
  end
end
