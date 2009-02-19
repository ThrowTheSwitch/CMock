
class CMockConfig

  CMockTreatAsDefaults = 
  {
      'INT'   => ['int','char','short','long','int8','int16','int32',
                  'int8_t','int16_t','int32_t', 'bool','bool_t','BOOL','BOOL_T',
                  'INT8','INT16','INT32','INT8_T','INT16_T','INT32_T'],
      'HEX32' => ['unsigned int', 'unsigned long', 'uint32', 'uint32_t', 'UINT32','UINT32_T'],
      'HEX16' => ['unsigned short', 'uint16', 'uint16_t', 'UINT16', 'UINT16_T'],
      'HEX8'  => ['unsigned char', 'uint8', 'uint8_t', 'UINT8', 'UINT8_T'],
      'STRING'=> ['char*', 'const char*', 'pCHAR', 'cstring', 'CSTRING']
  }
  
  CMockDefaultOptions = 
  {
    :mock_path => 'mocks',
    :includes => [],
    :plugins => ['cexception', 'ignore'],
    :tab => '  ',
    :expect_call_count_type => 'unsigned short',
    :enforce_strict_ordering => false,
    :ignore_bool_type => 'unsigned char',
    :cexception_include => nil,
    :cexception_throw_type => 'int',
    :unity_helper => false,
    :treat_as => CMockTreatAsDefaults,
    :memcpy_if_unknown => true,
    :when_ptr_star =>:compare_data,
    :when_ptr_brackets => :compare_array,
  }
  
  def initialize(options=nil)
    case(options)
      when NilClass then options = CMockDefaultOptions.clone 
      when String   then options = CMockDefaultOptions.clone.merge(load_config_file_from_yaml(options))
      when Hash     then options = CMockDefaultOptions.clone.merge(options)
      else          raise "If you specify parameters, it should be a filename or a hash of options"
    end
    @options = options
    @options.each_key { |key| eval("def #{key}() return @options[:#{key}] end") }
  end
  
  def load_config_file_from_yaml yaml_filename
    require 'yaml'
    require 'fileutils'
    YAML.load(File.read(yaml_filename))['cmock']
  end
  
  def set_path(path)
    @src_path = path
  end
  
  def load_unity_helper
    return File.new(@options[:unity_helper]).read if (@options[:unity_helper])
    return nil
  end
end
