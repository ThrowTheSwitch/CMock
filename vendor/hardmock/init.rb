# This file allows Hardmock to be used as a rails plugin

if RAILS_ENV == 'test'
  require 'hardmock'
  require 'assert_error'
end
