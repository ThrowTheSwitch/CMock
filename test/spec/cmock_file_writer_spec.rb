here = File.expand_path(File.dirname(__FILE__))
require "#{here}/spec_helper" #add this to execute tests from the spec directory
require 'cmock_file_writer'

describe CMockFileWriter do 
	before do
		@cmConfig = Object.new

		#create instance of class under test
		@subject = CMockFileWriter.new(@cmConfig)
	end

	describe 'initialize' do 
		it "have set up internal accessors correctly on init" do 
			result = @subject.config
			result.should == @cmConfig
		end
	end

	describe 'create_file' do

		it "should complain if a block was not specified when calling create" do 
			expect {@subject.create_file("text.txt")}.should raise_error
			# should.be_false
		end

		it "should perform block on new file" do
					# mock(@cmConfig).enforce_strict_ordering {false}
			mock(@cmConfig).mock_path {"testPath"}
			mock(@cmConfig).mock_path {"testPath"}

			FakeFile = Object.new
			mock(File).open("testPath/test.txt.new", "w").yields(FakeFile, "test.txt")
			mock(FakeFile).write("hello world"){nil}

			mock(File).exist?("testPath/test.txt") {true}
			mock(FileUtils).rm("testPath/test.txt")
			mock(FileUtils).cp("testPath/test.txt.new", "testPath/test.txt")
			mock(FileUtils).rm("testPath/test.txt.new")
			# Call function under test
			@subject.create_file("test.txt") {|f| f.write("hello world")}
		end

	end
end
