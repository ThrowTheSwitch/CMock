
class CMockConfig
  
  CMockDefaultOptions = 
  {
    :mock_path => 'mocks',
    :mock_prefix => 'Mock',
    :includes => [],
    :plugins => ['cexception', 'ignore'],
    :tab => '  ',
    :expect_call_count_type => 'unsigned short',
    :enforce_strict_ordering => false,
    :ignore_bool_type => 'unsigned char',
    :cexception_include => nil,
    :cexception_throw_type => 'int',
    :unity_helper => false,
    :treat_as => {},
    :memcpy_if_unknown => true,
    :when_ptr_star =>:compare_data, #the options being :compare_ptr, :compare_data, :compare_array
    :when_ptr_brackets => :compare_array, #not really supported yet
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

  def standard_treat_as_map 
    {
      'int'             => 'INT',
      'char'            => 'INT',
      'short'           => 'INT',
      'long'            => 'INT',
      'int8'            => 'INT',
      'int16'           => 'INT',
      'int32'           => 'INT',
      'int8_t'          => 'INT',
      'int16_t'         => 'INT',
      'int32_t'         => 'INT',
      'INT8_T'          => 'INT',
      'INT16_T'         => 'INT',
      'INT32_T'         => 'INT',
      'bool'            => 'INT',
      'bool_t'          => 'INT',
      'BOOL'            => 'INT',
      'BOOL_T'          => 'INT',
      'unsigned int'    => 'HEX32',
      'unsigned long'   => 'HEX32',
      'uint32'          => 'HEX32',
      'uint32_t'        => 'HEX32',
      'UINT32'          => 'HEX32',
      'UINT32_T'        => 'HEX32',
      'unsigned short'  => 'HEX16',
      'uint16'          => 'HEX16',
      'uint16_t'        => 'HEX16',
      'UINT16'          => 'HEX16',
      'UINT16_T'        => 'HEX16',
      'unsigned char'   => 'HEX8',
      'uint8'           => 'HEX8',
      'uint8_t'         => 'HEX8',
      'UINT8'           => 'HEX8',
      'UINT8_T'         => 'HEX8',
      'char*'           => 'STRING',
      'pCHAR'           => 'STRING',
      'cstring'         => 'STRING',
      'CSTRING'         => 'STRING',
    }
  end
end
