require 'test_helper'

module RGeo
  module ActiveRecord  # :nodoc:
    module PostGISAdapter  # :nodoc:
      module Tests  # :nodoc:
        class SpatialQueriesTest < ActiveSupport::TestCase  # :nodoc:

          def test_ignore_tables
            assert_equal %w(geometry_columns spatial_ref_sys layer topology), ::ActiveRecord::SchemaDumper.ignore_tables
          end

        end
      end
    end
  end
end
