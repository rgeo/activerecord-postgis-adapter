# frozen_string_literal: true

require_relative "../test_helper"

module PostGIS
  class SpatialQueriesTest < ActiveSupport::TestCase
    def test_ignore_tables
      expect_to_ignore = %w[
        geography_columns
        geometry_columns
        layer
        raster_columns
        raster_overviews
        spatial_ref_sys
        topology
      ]
      ignored_tables =
        if ::ActiveRecord.respond_to?(:schema_ignored_tables)
          ::ActiveRecord.schema_ignored_tables
        else
          ::ActiveRecord::SchemaDumper.ignore_tables
        end
      assert_equal expect_to_ignore, ignored_tables
    end
  end
end
