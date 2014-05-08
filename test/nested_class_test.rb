require 'test_helper'

module RGeo
  module ActiveRecord  # :nodoc:
    module PostGISAdapter  # :nodoc:
      module Tests  # :nodoc:
        class NestedClassTest < BASE_TEST_CLASS  # :nodoc:
          DATABASE_CONFIG_PATH = ::File.dirname(__FILE__) + '/database.yml'
          OVERRIDE_DATABASE_CONFIG_PATH = ::File.dirname(__FILE__) + '/database_local.yml'

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
                establish_connection(DATABASE_CONFIG)
              end
              Foo::Bar.connection.create_table(:foo_bars) do |t|
                t.column 'latlon', :point, :srid => 3785
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
