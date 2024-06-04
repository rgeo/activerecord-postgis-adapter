# frozen_string_literal: true

# The activerecord-postgis-adapter gem installs the *postgis*
# connection adapter into ActiveRecord.

# :stopdoc:

require "rgeo/active_record"

require "active_record/connection_adapters"
require "active_record/connection_adapters/postgresql_adapter"
require_relative "postgis/version"
require_relative "postgis/column_methods"
require_relative "postgis/schema_statements"
require_relative "postgis/database_statements"
require_relative "postgis/spatial_column_info"
require_relative "postgis/spatial_table_definition"
require_relative "postgis/spatial_column"
require_relative "postgis/arel_tosql"
require_relative "postgis/oid/spatial"
require_relative "postgis/oid/date_time"
require_relative "postgis/type" # has to be after oid/*
require_relative "postgis/create_connection"
# :startdoc:

module ActiveRecord
  module ConnectionHandling # :nodoc:
    def postgis_adapter_class
      ConnectionAdapters::PostGISAdapter
    end

    def postgis_connection(config)
      postgis_adapter_class.new(config)
    end
  end

  module ConnectionAdapters
    register "postgis", "ActiveRecord::ConnectionAdapters::PostGISAdapter", "active_record/connection_adapters/postgis_adapter"

    class PostGISAdapter < PostgreSQLAdapter
      ADAPTER_NAME = 'PostGIS'

      SPATIAL_COLUMN_OPTIONS =
        {
          geography:           { geographic: true },
          geometry:            {},
          geometry_collection: {},
          line_string:         {},
          multi_line_string:   {},
          multi_point:         {},
          multi_polygon:       {},
          spatial:             {},
          st_point:            {},
          st_polygon:          {},
        }

      # http://postgis.17.x6.nabble.com/Default-SRID-td5001115.html
      DEFAULT_SRID = 0

      include PostGIS::SchemaStatements
      include PostGIS::DatabaseStatements

      def arel_visitor # :nodoc:
        Arel::Visitors::PostGIS.new(self)
      end

      def self.spatial_column_options(key)
        SPATIAL_COLUMN_OPTIONS[key]
      end

      def postgis_lib_version
        @postgis_lib_version ||= select_value("SELECT PostGIS_Lib_Version()")
      end

      def default_srid
        DEFAULT_SRID
      end

      class << self
        def initialize_type_map(map = type_map)
          %w[
            geography
            geometry
            geometry_collection
            line_string
            multi_line_string
            multi_point
            multi_polygon
            st_point
            st_polygon
          ].each do |geo_type|
            map.register_type(geo_type) do |_, _, sql_type|
              # sql_type is a string that comes from the database definition
              # examples:
              #   "geometry(Point,4326)"
              #   "geography(Point,4326)"
              #   "geometry(Polygon,4326) NOT NULL"
              #   "geometry(Geography,4326)"
              geo_type, srid, has_z, has_m, geographic = PostGIS::OID::Spatial.parse_sql_type(sql_type)
              PostGIS::OID::Spatial.new(geo_type: geo_type, srid: srid, has_z: has_z, has_m: has_m, geographic: geographic)
            end
          end

          super
        end

        def native_database_types
          @native_database_types ||= begin
            default_types = PostgreSQLAdapter.native_database_types
            default_types.merge({
              geography:           { name: "geography" },
              geometry:            { name: "geometry" },
              geometry_collection: { name: "geometry_collection" },
              line_string:         { name: "line_string" },
              multi_line_string:   { name: "multi_line_string" },
              multi_point:         { name: "multi_point" },
              multi_polygon:       { name: "multi_polygon" },
              spatial:             { name: "geometry" },
              st_point:            { name: "st_point" },
              st_polygon:          { name: "st_polygon" }
            })
          end
        end
      end

      def srs_database_columns
        {
          auth_name_column: "auth_name",
          auth_srid_column: "auth_srid",
          proj4text_column: "proj4text",
          srtext_column:    "srtext",
        }
      end

      def quote(value)
        if RGeo::Feature::Geometry.check_type(value)
          "'#{RGeo::WKRep::WKBGenerator.new(hex_format: true, type_format: :ewkb, emit_ewkb_srid: true).generate(value)}'"
        elsif value.is_a?(RGeo::Cartesian::BoundingBox)
          "'#{value.min_x},#{value.min_y},#{value.max_x},#{value.max_y}'::box"
        else
          super
        end
      end

      def quote_default_expression(value, column)
        if column.type == :geography || column.type == :geometry
          quote(value)
        else
          super
        end
      end

      # PostGIS specific types
      [
        :geography,
        :geometry,
        :geometry_collection,
        :line_string,
        :multi_line_string,
        :multi_point,
        :multi_polygon,
        :st_point,
        :st_polygon,
      ].each do |geo_type|
        ActiveRecord::Type.register(geo_type, PostGIS::OID::Spatial, adapter: :postgis)
      end
    end
  end
  SchemaDumper.ignore_tables |= %w[
    geography_columns
    geometry_columns
    layer
    raster_columns
    raster_overviews
    spatial_ref_sys
    topology
  ]
  Tasks::DatabaseTasks.register_task(/postgis/, "ActiveRecord::Tasks::PostgreSQLDatabaseTasks")
end

# if using JRUBY, create ArJdbc::PostGIS module
# and prepend it to the PostgreSQL adapter since
# it is the default adapter_spec.
# see: https://github.com/jruby/activerecord-jdbc-adapter/blob/master/lib/arjdbc/postgresql/adapter.rb#27
if RUBY_ENGINE == "jruby"
  module ArJdbc
    module PostGIS
      ADAPTER_NAME = 'PostGIS'

      def adapter_name
        ADAPTER_NAME
      end
    end
  end

  ArJdbc::PostgreSQL.prepend(ArJdbc::PostGIS)
end
