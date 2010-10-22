# ==========================================
#   CMock Project - Automatic Mock Generation for C
#   Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
#   [Released under MIT License. Please refer to license.txt for details]
# ========================================== 
[ "/../config/test_environment",
  "/../vendor/behaviors/lib/behaviors"
].each do |req|
  require File.expand_path(File.dirname(__FILE__)) + req
end

#gem install test-unit -v 1.2.3
ruby_version = RUBY_VERSION.split('.')
if (ruby_version[1].to_i == 9) and (ruby_version[2].to_i > 1)
  require 'rubygems'
  gem 'test-unit'
end
require 'test/unit'
require 'hardmock'

class Test::Unit::TestCase
  extend Behaviors
  
  #these are helpful test structures which can be used during tests
  
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
end
