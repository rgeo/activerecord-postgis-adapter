require 'minitest/autorun'
require 'minitest/pride'
require 'rgeo/active_record/adapter_test_helper'

begin
  require 'byebug'
rescue LoadError
  # ignore
end


DATABASE_CONFIG_PATH = ::File.dirname(__FILE__) + '/database.yml'
OVERRIDE_DATABASE_CONFIG_PATH = ::File.dirname(__FILE__) + '/database_local.yml'
