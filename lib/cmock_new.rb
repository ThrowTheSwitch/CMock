
class CMock
  attr_accessor :mocks_path, :includes, :interface_parser

  def initialize(mocks_path='mocks', includes=[], interface_parser=nil)
    @mocks_path = mocks_path
    @includes = includes
    @interface_parser = interface_parser
  end
  
  def generate(module_header)
    @interface_parser.extract_interface(module_header)
  end
  
end