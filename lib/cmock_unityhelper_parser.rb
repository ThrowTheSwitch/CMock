class CMockUnityHelperParser
  
  attr_accessor :c_types
  
  def initialize(config)
    @config = config
    @c_types = map_C_types.merge(import_source)
  end

  def get_helper(ctype)
    lookup = ctype.gsub(/const\s+/,'').strip.gsub(/\s+/,'_')
    return @c_types[lookup] if (@c_types[lookup])
    raise("Don't know how to test #{ctype} and memory tests are disabled!") unless @config.memcmp_if_unknown
    return 'TEST_ASSERT_EQUAL_MEMORY_MESSAGE'
  end
  
  private ###########################
  
  def map_C_types
    c_types = {}
    [@config.standard_treat_as_map, @config.treat_as].each do |pairs|
      pairs.each_pair do |ctype, expecttype|
        c_types[ctype.gsub(/\s+/,'_')] = "TEST_ASSERT_EQUAL_#{expecttype}_MESSAGE"
      end unless pairs.nil?
    end
    c_types
  end
  
  def import_source
    source = @config.load_unity_helper
    return {} if source.nil?
    
    c_types = {}
    source = source.gsub(/\/\/.*$/, '') #remove line comments
    source = source.gsub(/\/\*.*?\*\//m, '') #remove block comments
     
    #scan for comparison helpers
    m = Regexp.new('^\s*#define\s+(TEST_ASSERT_EQUAL_(\w+)_MESSAGE|TEST_ASSERT_EQUAL_(\w+))\s*\(' + Array.new(2,'\s*\w+\s*').join(',') + '\)')
    a = source.scan(m).flatten.compact
    (a.size/2).times do |i|
      expect = a[i*2]
      ctype = a[(i*2)+1]
      c_types[ctype] = expect unless expect.include?("_ARRAY")
    end
      
    #scan for array variants of those helpers
    m = Regexp.new('^\s*#define\s+(TEST_ASSERT_EQUAL_(\w+_ARRAY)_MESSAGE|TEST_ASSERT_EQUAL_(\w+_ARRAY))\s*\(' + Array.new(3,'\s*\w+\s*').join(',') + '\)')
    a = source.scan(m).flatten.compact
    (a.size/2).times do |i|
      expect = a[i*2]
      ctype = a[(i*2)+1]
      c_types[ctype.gsub('_ARRAY','*')] = expect
    end
    
    c_types
  end
end
