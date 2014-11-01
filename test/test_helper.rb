require 'minitest/autorun'
require 'minitest/pride'
require 'rgeo/active_record/adapter_test_helper'

begin
  require 'byebug'
rescue LoadError
  # ignore
end

class ActiveSupport::TestCase
  self.test_order = :random
end
