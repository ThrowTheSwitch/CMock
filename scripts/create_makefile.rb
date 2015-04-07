require 'cmock'
require 'fileutils'
abs_root = FileUtils.pwd
cmock_dir = File.expand_path(ENV.fetch('CMOCK_DIR', File.join(abs_root, '..', '..')))
puts "___CMOCK: #{cmock_dir}"
unity_dir = File.join(cmock_dir, 'vendor', 'unity')
puts "___UNITY: #{unity_dir}"
require "#{unity_dir}/auto/generate_test_runner"

src_dir =  ENV.fetch('SRC_DIR',  './src')
test_dir = ENV.fetch('TEST_DIR', './test')
unity_src = File.join(unity_dir, 'src')
cmock_src = File.join(cmock_dir, 'src')
build_dir = ENV.fetch('BUILD_DIR', './build')
test_build_dir = ENV.fetch('TEST_BUILD_DIR', File.join(build_dir, 'test'))
obj_dir = File.join(test_build_dir, 'obj')
unity_obj = File.join(obj_dir, 'unity.o')
cmock_obj = File.join(obj_dir, 'cmock.o')
runners_dir = File.join(test_build_dir, 'runners')
mocks_dir = File.join(test_build_dir, 'mocks')
test_bin_dir = test_build_dir
mock_prefix = ENV.fetch('TEST_MOCK_PREFIX', 'mock_')
test_makefile = ENV.fetch('TEST_MAKEFILE', File.join(test_build_dir, 'MakefileTestSupport'))
MOCK_MATCHER = /#{mock_prefix}[A-Za-z_][A-Za-z0-9_\-\.]+/

[test_build_dir, obj_dir, runners_dir, mocks_dir, test_bin_dir].each do |dir|
  FileUtils.mkdir_p dir
end

all_headers_to_mock = []

File.open(test_makefile, "w") do |mkfile|

  # Define make variables
  mkfile.puts "CC ?= gcc"
  mkfile.puts "BUILD_DIR ?= ./build"
  mkfile.puts "SRC_DIR ?= ./src"
  mkfile.puts "TEST_DIR ?= ./test"
  mkfile.puts "CMOCK_DIR ?= #{cmock_dir}"
  mkfile.puts "UNITY_DIR ?= #{unity_dir}"
  mkfile.puts "TEST_BUILD_DIR ?= ${BUILD_DIR}/test"
  mkfile.puts "TEST_MAKEFILE = ${TEST_BUILD_DIR}/MakefileTestSupport"
  mkfile.puts "OBJ ?= ${BUILD_DIR}/obj"
  mkfile.puts "OBJ_DIR = ${OBJ}"
  mkfile.puts ""

  # Build Unity
  mkfile.puts "#{unity_obj}: #{unity_src}/unity.c"
  mkfile.puts "\t${CC} -o $@ -c $< -I #{unity_src}"
  mkfile.puts ""

  # Build CMock
  mkfile.puts "#{cmock_obj}: #{cmock_src}/cmock.c"
  mkfile.puts "\t${CC} -o $@ -c $< -I #{unity_src} -I #{cmock_src}"
  mkfile.puts ""

  test_sources = Dir["#{test_dir}/**/test_*.c"]
  test_targets = []
  generator = UnityTestRunnerGenerator.new
  all_headers = Dir["#{src_dir}/**/*.h"]

  test_sources.each do |test|
    module_name = File.basename(test, '.c')
    src_module_name = module_name.sub(/^test_/, '')
    test_obj = File.join(obj_dir, "#{module_name}.o")
    runner_source = File.join(runners_dir, "runner_#{module_name}.c")
    runner_obj = File.join(obj_dir, "runner_#{module_name}.o")
    test_bin = File.join(test_bin_dir, module_name)
    test_results = File.join(test_bin_dir, module_name + '.result')

    # Build main project modules, with TEST defined
    module_src = File.join(src_dir, "#{src_module_name}.c")
    module_obj = File.join(obj_dir, "#{src_module_name}.o")
    mkfile.puts "#{module_obj}: #{module_src}"
    mkfile.puts "\t${CC} -o $@ -c $< -DTEST -I #{src_dir}"
    mkfile.puts ""

    # Create runners
    mkfile.puts "#{runner_source}: #{test}"
    mkfile.puts "\t@UNITY_DIR=${UNITY_DIR} ruby ${CMOCK_DIR}/scripts/create_runner.rb #{test} #{runner_source}"
    mkfile.puts ""

    # Build runner
    mkfile.puts "#{runner_obj}: #{runner_source}"
    mkfile.puts "\t${CC} -o $@ -c $< -I #{src_dir} -I #{mocks_dir} -I #{unity_src} -I #{cmock_src}"
    mkfile.puts ""

    # Collect mocks to generate
    cfg = {
      src: test,
      includes: generator.find_includes(File.readlines(test).join(''))
    }
    system_mocks = cfg[:includes][:system].select{|name| name =~ MOCK_MATCHER}
    raise "Mocking of system headers is not yet supported!" if !system_mocks.empty?
    local_mocks = cfg[:includes][:local].select{|name| name =~ MOCK_MATCHER}
    module_names_to_mock = local_mocks.map{|name| "#{name.sub(/#{mock_prefix}/,'')}.h"}
    headers_to_mock = []
    module_names_to_mock.each do |name|
      header_to_mock = nil
      all_headers.each do |header|
        if (header =~ /[\/\\]?#{name}$/)
          header_to_mock = header
          break
        end
      end
      raise "Module header '#{name}' not found to mock!" unless header_to_mock
      headers_to_mock << header_to_mock 
    end
    all_headers_to_mock += headers_to_mock
    mock_objs = headers_to_mock.map do |hdr|
      mock_name = mock_prefix + File.basename(hdr, '.h')
      File.join(mocks_dir, mock_name + '.o')
    end
    all_headers_to_mock.uniq!

    # Build test suite
    mkfile.puts "#{test_obj}: #{test} #{module_obj} #{mock_objs.join(' ')}"
    mkfile.puts "\t${CC} -o $@ -c $< -I #{src_dir} -I #{unity_src} -I #{cmock_src} -I #{mocks_dir}"
    mkfile.puts ""

    # Build test suite executable
    test_objs = "#{test_obj} #{runner_obj} #{module_obj} #{mock_objs.join(' ')} #{unity_obj} #{cmock_obj}"
    mkfile.puts "#{test_bin}: #{test_objs}"
    mkfile.puts "\t${CC} -o $@ #{test_objs}"
    mkfile.puts ""

    # Run test suite and generate report
    mkfile.puts "#{test_results}: #{test_bin}"
    mkfile.puts "\t#{test_bin} &> #{test_results}"
    mkfile.puts ""

    test_targets << test_bin
  end

  # Generate and build mocks
  all_headers_to_mock.each do |hdr|
    mock_name = mock_prefix + File.basename(hdr, '.h')
    mock_header = File.join(mocks_dir, mock_name + '.h')
    mock_src = File.join(mocks_dir, mock_name + '.c')
    mock_obj = File.join(mocks_dir, mock_name + '.o')

    mkfile.puts "#{mock_src}: #{hdr}"
    mkfile.puts "\t@CMOCK_DIR=${CMOCK_DIR} ruby ${CMOCK_DIR}/scripts/create_mock.rb #{hdr}"
    mkfile.puts ""

    mkfile.puts "#{mock_obj}: #{mock_src} #{mock_header}"
    mkfile.puts "\t${CC} -o $@ -c $< -I #{mocks_dir} -I #{src_dir} -I #{unity_src} -I #{cmock_src}"
    mkfile.puts ""
  end

  # Create test summary task
  mkfile.puts "test_summary:"
  mkfile.puts "\t@UNITY_DIR=${UNITY_DIR} ruby ${CMOCK_DIR}/scripts/test_summary.rb"
  mkfile.puts ""
  mkfile.puts ".PHONY: test_summary"
  mkfile.puts ""

  # Create target to run all tests
  mkfile.puts "test: #{test_targets.map{|t| t + '.result'}.join(' ')} test_summary"
  mkfile.puts ""

end
