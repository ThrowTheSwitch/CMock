require "#{ENV['CMOCK_DIR']}/lib/cmock"

raise "Header file to mock must be specified!" unless ARGV.length >= 1

mock_out = ENV.fetch('MOCKS_DIR', './build/test/mocks')
mock_prefix = ENV.fetch('MOCK_PREFIX', 'mock_')
srcdir =  ENV.fetch("SRC_DIR", nil)
cmock = CMock.new({:plugins => [:ignore, :return_thru_ptr], :mock_prefix => mock_prefix, :mock_path => mock_out, :srcdir => srcdir})
cmock.setup_mocks(ARGV[0])
