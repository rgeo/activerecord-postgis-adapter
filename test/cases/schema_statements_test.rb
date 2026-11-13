# frozen_string_literal: true

require_relative "../test_helper"

module PostGIS
  class SchemaStatementsTest < ActiveSupport::TestCase
    BATCH_TABLES = %w[spatial_batch_parks spatial_batch_roads].freeze

    def teardown
      BATCH_TABLES.each { |table| SpatialModel.lease_connection.drop_table(table, if_exists: true) }
    end

    def test_initialize_type_map
      SpatialModel.with_connection do |connection|
        connection.connect!
        initialized_types = connection.send(:type_map).keys

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

    def test_columns_of_many_tables_reads_types_and_geometry_columns_once
      unless ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.private_method_defined?(:fetch_column_definitions)
        skip "Reading the columns of many tables at once requires Rails 8.2"
      end

      create_batch_tables
      # A new connection, so neither the spatial types nor geometry_columns are loaded yet
      connection = ActiveRecord::ConnectionAdapters::PostGISAdapter.new(SpatialModel.connection_db_config.configuration_hash)
      connection.tables

      sqls = []
      subscriber = ->(*, payload) { sqls << payload[:sql] }
      columns = ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
        connection.columns(BATCH_TABLES)
      end

      assert_equal 1, sqls.grep(/FROM pg_type AS t/).size, "spatial types should be loaded in one query"
      assert_equal 1, sqls.grep(/FROM geometry_columns/).size, "geometry_columns should be read in one query"
      BATCH_TABLES.each do |table|
        assert_equal SpatialModel.lease_connection.columns(table), columns[table]
        raw = columns[table].find { |c| c.name == "raw" }
        assert_equal 3857, raw.srid
        assert_equal RGeo::Feature::Geometry, raw.geometric_type
      end
    ensure
      connection&.disconnect!
    end

    private

    def create_batch_tables
      BATCH_TABLES.each do |table|
        SpatialModel.lease_connection.create_table(table, force: true) do |t|
          t.column "name", :string
          t.column "latlon", :st_point, srid: 3857
          t.column "region", :st_polygon, srid: 4326, geographic: true
        end
        # A column with no typmod gets its srid from geometry_columns
        SpatialModel.lease_connection.execute("ALTER TABLE #{table} ADD COLUMN raw geometry CHECK (st_srid(raw) = 3857)")
      end
    end
  end
end
