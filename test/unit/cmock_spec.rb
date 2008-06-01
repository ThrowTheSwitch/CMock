$here = File.dirname(__FILE__)
require "#{$here}/../../config/environment"
require 'cmock'

describe CMock do

  before(:each) do
    @interface_parser = mock('InterfaceParser')
    @cmock = CMock.new('mocks', [], @interface_parser)
  end
  
  it "should default mocks path to 'mocks'" do
    @cmock.mocks_path.should == 'mocks'
  end
  
  it "should allow mocks path to be specified in constructor" do
    @cmock = CMock.new('yoohoo')
    @cmock.mocks_path.should == 'yoohoo'
  end
  
  it "should default includes to empty array" do
    @cmock.includes.should == []
  end
  
  it "should allow includes to be specified in constructor" do
    includes = ['fun', 'stuff']
    @cmock = CMock.new('blah', includes)
    @cmock.includes.should == includes
  end
  
  it "should generate a mock module" do
    @cmock.should respond_to(:generate)
  end
  
  it "should delegate to parser to extract interface" do
    module_header = 'my_module.h'
    @interface_parser.should_receive(:extract_interface).with(module_header)
    @cmock.generate(module_header)
  end
  
end
