$here = File.dirname __FILE__
require "#{$here}/cmock_header_parser"
require "#{$here}/cmock_generator"
require "#{$here}/cmock_config"

class CMockSetup

  attr_accessor :mocks_path, :auto_path

  def initialize(mocks_path='mocks', includes=[], use_cexception=true, allow_ignore_mock=false)
    @mocks_path = mocks_path
    @includes = includes
    @use_cexception = use_cexception
    @allow_ignore_mock = allow_ignore_mock
  end
  
  def setup_mocks(files)
    files.each do |src|
      generate_mock src
    end
  end

  private

  def generate_mock(src)
    name = File.basename(src, '.h')
    path = File.dirname(src)
    
    cmc = CMockConfig.new(path, @mocks_path, @includes, @use_cexception, @allow_ignore_mock)
    cmp = CMockHeaderParser.new(File.read(src))
    cmg = CMockGenerator.new(cmc, name)
    
    puts "Creating mock for #{name}..."
    
    parsed_stuff = cmp.parse
    cmg.create_mock(parsed_stuff)
  end
end
