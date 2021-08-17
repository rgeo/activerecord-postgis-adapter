# frozen_string_literal: true

# The activerecord-postgis-adapter gem installs the *postgis*
# connection adapter into ActiveRecord.

# :stopdoc:

require "rgeo/active_record"

require "active_record/connection_adapters"
require "active_record/connection_adapters/postgresql_adapter"
require "active_record/connection_adapters/postgis/version"
require "active_record/connection_adapters/postgis/column_methods"
require "active_record/connection_adapters/postgis/schema_statements"
require "active_record/connection_adapters/postgis/database_statements"
require "active_record/connection_adapters/postgis/spatial_column_info"
require "active_record/connection_adapters/postgis/spatial_table_definition"
require "active_record/connection_adapters/postgis/spatial_column"
require "active_record/connection_adapters/postgis/arel_tosql"
require "active_record/connection_adapters/postgis/setup"
require "active_record/connection_adapters/postgis/oid/spatial"
require "active_record/connection_adapters/postgis/type" # has to be after oid/*
require "active_record/connection_adapters/postgis/create_connection"
require "active_record/connection_adapters/postgis/postgis_database_tasks"

ActiveRecord::ConnectionAdapters::PostGIS.initial_setup

if defined?(Rails::Railtie)
  require "active_record/connection_adapters/postgis/railtie"
end

# :startdoc:

module ActiveRecord
  module ConnectionAdapters
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
