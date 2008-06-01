
class CMockConfig

  attr_accessor :src_path, :mock_path, :tab, :includes, :use_cexception, :allow_ignore_mock, :call_count_type, :ignore_bool_type
  attr_accessor :throw_type
  
  def initialize(src_path='src', mock_path='mocks', includes=[], use_cexception=true, allow_ignore_mock=false, tab='    ')
    @src_path = src_path
    @mock_path = mock_path
    @tab = tab
    @throw_type = 'int'
    @call_count_type = 'unsigned short'
    @ignore_bool_type = 'unsigned char'
    @includes = includes
    @use_cexception = use_cexception
    @allow_ignore_mock = allow_ignore_mock
  end
end
