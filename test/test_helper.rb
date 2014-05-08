require 'minitest/autorun'
require 'rgeo/active_record/adapter_test_helper'

BASE_TEST_CLASS = if ActiveRecord::VERSION::STRING > '4.1'
                    Minitest::Test
                  else
                    MiniTest::Unit::TestCase
                  end
