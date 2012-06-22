here = File.expand_path(File.dirname(__FILE__))
require "#{here}/spec_helper" #add this to execute tests from the spec directory
require 'cmock_generator_plugin_array'

describe :CMockGeneratorPluginArray do 
	before do
		@cmConfig = Object.new
		@cmUtils = Object.new
		mock(@cmConfig).when_ptr {:compare_data}
		mock(@cmConfig).enforce_strict_ordering {false}
		mock(@cmUtils).helpers { {} }
		#create instance of class under test
		@subject = CMockGeneratorPluginArray.new(@cmConfig, @cmUtils)
	end

	it "should not respond to include_files" do
			# @subject.should_not respond_to(:include_files)
  end
 
 # 	it "should not add to typedef structure for functions of " + 
 # 	   "style 'int* func(void)'" do
 #    	function = {:name => "Oak", :args => [], :return => :int_ptr}
 #    	returned = @subject.instance_typedefs(function)
 #    	returned.should == ""
 #  	end
  
	# it "should add to typedef structure mock needs of functions of style "+
	# 	 "'void func(int chicken, int* pork)'" do 
	#     arg1 = { :name => "chicken", :type => "int", :ptr? => false}
	# 	arg2 = { :name => "pork", :type => "int*", :ptr? => true}
	#     function = {:name => "Cedar",
	# 	  	  :args => [arg1, arg2],
	# 		    :return => :void}
	#     expected = "  int Expected_pork_Depth;\n"
	#     returned = @subject.instance_typedefs(function)
	#     returned.should == expected
 # 	end

 # 	it "should not add an additional mock interface for functions not containing pointers" do
	#     function = {:name => "Maple", :args_string => "int blah", :return  => :string,
	#     	:contains_ptr? => false}
 #    	returned = @subject.mock_function_declarations(function)
 #    	returned.should_be nil
 # 	end
	
	# describe 'create_file' do
	# 	it "complain if a block was not specified when calling create" do 
	# 		expect {@subject.create_file("text.txt")}.should raise_error
	# 		# should.be_false
	# 	end
	# end
end
