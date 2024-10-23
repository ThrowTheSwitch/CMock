# -*- encoding: utf-8 -*-
$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
require "lib/cmock_version"
require 'date'

Gem::Specification.new do |s|
  s.name        = "cmock"
  s.version     = CMockVersion::GEM
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Mark VanderVoord", "Michael Karlesky", "Greg Williams"]
  s.email       = ["mark@vandervoord.net", "michael@karlesky.net", "barney.williams@gmail.com"]
  s.homepage    = "http://throwtheswitch.org/cmock"
  s.summary     = "CMock is a mocking framework for C unit testing. It's a member of the ThrowTheSwitch.org family of tools."
  s.description = <<-DESC
CMock is a mocking framework for C unit testing. It accepts header files and generates mocks automagically for you.
  DESC
  s.licenses    = ['MIT']

  s.metadata = {
    "homepage_uri"      => s.homepage,
    "bug_tracker_uri"   => "https://github.com/ThrowTheSwitch/CMock/issues",
    "documentation_uri" => "https://github.com/ThrowTheSwitch/CMock/blob/master/docs/CMock_Summary.md",
    "mailing_list_uri"  => "https://groups.google.com/forum/#!categories/throwtheswitch/cmock",
    "source_code_uri"   => "https://github.com/ThrowTheSwitch/CMock"
  }
  
  s.required_ruby_version = ">= 3.0.0"

  s.files      += Dir['**/*']
  s.test_files  = Dir['test/**/*']
  s.executables = ['lib/cmock.rb']

  s.require_paths = ["lib"]
end
