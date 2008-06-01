$here = File.dirname __FILE__
require "#{$here}/cmock_generator"

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
    cmg = CMockGenerator.new(name, path, @mocks_path, @includes, @use_cexception, @allow_ignore_mock)
    $stderr.puts "Creating mock for #{name}..."
    $stderr.flush
    cmg.create_mock
  end
end
