require 'minitest/autorun'
require 'minitest/pride'
require 'active_record'
if ActiveRecord::VERSION::STRING >= '4.2'
  require 'active_record/connection_adapters/abstract_adapter'
end
require 'rgeo/active_record/adapter_test_helper'

begin
  require 'byebug'
rescue LoadError
  # ignore
end
