# frozen_string_literal: true

require "test_helper"

class SchemaStatementsTest < ActiveSupport::TestCase
  def test_initialize_type_map
    initialized_types = SpatialModel.connection.send(:type_map).keys

    # PostGIS types must be initialized first, so
    # ActiveRecord::ConnectionAdapters::PostgreSQLAdapter#load_additional_types can use them.
    # https://github.com/rails/rails/blob/8d57cb39a88787bb6cfb7e1c481556ef6d8ede7a/activerecord/lib/active_record/connection_adapters/postgresql_adapter.rb#L593
    assert_equal initialized_types.first(9), %w[
      geography
      geometry
      geometry_collection
      line_string
      multi_line_string
      multi_point
      multi_polygon
      st_point
      st_polygon
    ]
  end
end
