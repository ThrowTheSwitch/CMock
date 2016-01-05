# ==========================================
#   CMock Project - Automatic Mock Generation for C
#   Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
#   [Released under MIT License. Please refer to license.txt for details]
# ==========================================


require 'minitest/autorun'

def create_mocks(*mocks)
  mocks.each do |mock|
    eval "@#{mock} = Minitest::Mock.new"
  end
end

def create_stub(funcs)
  stub = Class.new
  #if (RUBY_VERSION.split('.')[0].to_i >= 2)
  #  funcs.each_pair {|k,v| stub.define_singleton_method(k) {|*unused| return v } }
  #else
    blob = "class << stub\n"
    funcs.each_pair {|k,v| blob += "def #{k.to_s}(unused=nil)\n #{v.inspect}\nend\n" }
    blob += "end"
    eval blob
  #end
  stub
end

def test_return
  {
    :int     => {:type => "int",   :name => 'cmock_to_return', :ptr? => false, :const? => false, :void? => false, :str => 'int cmock_to_return'},
    :int_ptr => {:type => "int*",  :name => 'cmock_to_return', :ptr? => true,  :const? => false, :void? => false, :str => 'int* cmock_to_return'},
    :void    => {:type => "void",  :name => 'cmock_to_return', :ptr? => false, :const? => false, :void? => true,  :str => 'void cmock_to_return'},
    :string  => {:type => "char*", :name => 'cmock_to_return', :ptr? => false, :const? => true,  :void? => false, :str => 'const char* cmock_to_return'},
  }
end

def test_arg
  {
    :int        => {:type => "int",      :name => 'MyInt',       :ptr? => false, :const? => false},
    :int_ptr    => {:type => "int*",     :name => 'MyIntPtr',    :ptr? => true,  :const? => false},
    :mytype     => {:type => "MY_TYPE",  :name => 'MyMyType',    :ptr? => false, :const? => true},
    :mytype_ptr => {:type => "MY_TYPE*", :name => 'MyMyTypePtr', :ptr? => true,  :const? => false},
    :string     => {:type => "char*",    :name => 'MyStr',       :ptr? => false, :const? => true},
  }
end

