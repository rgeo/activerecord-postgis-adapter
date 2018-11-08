# frozen_string_literal: true

require "test_helper"

class SpatialQueriesTest < ActiveSupport::TestCase
  def test_ignore_tables
    expect_to_ignore = %w(
      geography_columns
      geometry_columns
      layer
      raster_columns
      raster_overviews
      spatial_ref_sys
      topology
    )
    assert_equal expect_to_ignore, ::ActiveRecord::SchemaDumper.ignore_tables
  end
end
