require 'minitest/autorun'
require 'rgeo/active_record/adapter_test_helper'


module RGeo
  module ActiveRecord  # :nodoc:
    module PostGISAdapter  # :nodoc:
      module Tests  # :nodoc:

        class TestNestedClass < ::MiniTest::Unit::TestCase  # :nodoc:

          DATABASE_CONFIG_PATH = ::File.dirname(__FILE__)+'/database.yml'
          OVERRIDE_DATABASE_CONFIG_PATH = ::File.dirname(__FILE__)+'/database_local.yml'
          include AdapterTestHelper


          module Foo
            def self.table_name_prefix
              'foo_'
            end
            class Bar < ::ActiveRecord::Base
            end
          end


          define_test_methods do


            def test_nested_model
              Foo::Bar.class_eval do
                establish_connection(TestNestedClass::DATABASE_CONFIG)
              end
              Foo::Bar.connection.create_table(:foo_bars) do |t_|
                t_.column 'latlon', :point, :srid => 3785
              end
              Foo::Bar.all
              Foo::Bar.connection.drop_table(:foo_bars)
            end


          end

        end

      end
    end
  end
end
