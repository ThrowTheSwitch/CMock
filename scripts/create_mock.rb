require "#{ENV['CMOCK_DIR']}/lib/cmock"

raise "Header file to mock must be specified!" unless ARGV.length >= 1

mock_out = ENV.fetch('MOCKS_DIR', './build/test/mocks')
mock_prefix = ENV.fetch('MOCK_PREFIX', 'mock_')

cmock_config = ENV.fetch('CMOCK_CONFIG', "")
if cmock_config.empty?
  cmock_config = {:plugins => [:ignore, :return_thru_ptr], :mock_prefix => mock_prefix, :mock_path => mock_out}
end

cmock = CMock.new(cmock_config)
cmock.setup_mocks(ARGV[0])
