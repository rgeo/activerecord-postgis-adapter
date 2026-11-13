# frozen_string_literal: true

require_relative "../test_helper"

module PostGIS
  class SchemaCacheTest < ActiveSupport::TestCase
    # Uses its own table because the adapter memoizes geometry_columns info per table name
    TABLE = "spatial_schema_cache_models"

    def setup
      SpatialModel.lease_connection.create_table(TABLE, force: true) do |t|
        t.column "name", :string
        t.column "shape", :geometry
        t.column "latlon", :st_point, srid: 3857
        t.column "path", :line_string, srid: 3785, has_z: true, has_m: true
        t.column "region", :st_polygon, srid: 4326, geographic: true
      end
    end

    def teardown
      SpatialModel.lease_connection.drop_table(TABLE, if_exists: true)
    end

    def test_json_schema_cache_round_trips_spatial_columns
      unless defined?(ActiveRecord::ConnectionAdapters::JSONSchemaCacheSerializer)
        skip "JSON schema cache format requires Rails 8.2"
      end

      serializer = ActiveRecord::ConnectionAdapters::JSONSchemaCacheSerializer
      pool = SpatialModel.connection_pool
      cache = ActiveRecord::ConnectionAdapters::SchemaCache.new
      columns = cache.columns(pool, TABLE)

      loaded = serializer.load(serializer.dump(cache)).columns(pool, TABLE)

      assert_equal columns, loaded
      region = loaded.find { |c| c.name == "region" }
      assert_equal RGeo::Feature::Polygon, region.geometric_type
      assert_equal({ srid: 4326, type: "st_polygon", geographic: true }, region.limit)
      path = loaded.find { |c| c.name == "path" }
      assert_equal({ srid: 3785, type: "line_string", has_z: true, has_m: true }, path.limit)
      assert_equal 3857, loaded.find { |c| c.name == "latlon" }.cast_type.spatial_factory.srid
    end
  end
end
