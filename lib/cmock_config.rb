
class CMockConfig

  CMockDefaultOptions = 
  {
    'mock_path' => 'mocks',
    'includes' => [],
    'plugins' => ['cexception', 'ignore'],
    'tab' => '  ',
    'expect_call_count_type' => 'unsigned short',
    'ignore_bool_type' => 'unsigned char',
    'cexception_include' => nil,
    'cexception_throw_type' => 'int',
  }
  
  def initialize(options=nil)
    case(options)
      when NilClass then options = CMockDefaultOptions.clone 
      when String   then options = CMockDefaultOptions.clone.merge(load_config_file_from_yaml(options))
      when Hash     then options = CMockDefaultOptions.clone.merge(options)
      else          raise "If you specify parameters, it should be a filename or a hash of options"
    end
    @options = options
    @options.each_key { |key| eval("def #{key}() return @options['#{key}'] end") }
  end
  
  def load_config_file_from_yaml yaml_filename
    require 'yaml'
    require 'fileutils'
    YAML.load(File.read(yaml_filename))['cmock']
  end
  
  def set_path(path)
    @src_path = path
  end
end
