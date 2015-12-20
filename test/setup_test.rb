require "test_helper"

class SpatialQueriesTest < ActiveSupport::TestCase  # :nodoc:
  def test_ignore_tables
    assert_equal %w(geometry_columns spatial_ref_sys layer topology), ::ActiveRecord::SchemaDumper.ignore_tables
  end
end
