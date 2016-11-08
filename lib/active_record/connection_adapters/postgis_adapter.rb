# The activerecord-postgis-adapter gem installs the *postgis*
# connection adapter into ActiveRecord.

# :stopdoc:

require "active_record/connection_adapters/postgresql_adapter"
require "rgeo/active_record"
require "active_record/connection_adapters/postgis/version"
require "active_record/connection_adapters/postgis/column_methods"
require "active_record/connection_adapters/postgis/schema_statements"
require "active_record/connection_adapters/postgis/spatial_column_info"
require "active_record/connection_adapters/postgis/spatial_table_definition"
require "active_record/connection_adapters/postgis/spatial_column"
require "active_record/connection_adapters/postgis/arel_tosql"
require "active_record/connection_adapters/postgis/setup"
require "active_record/connection_adapters/postgis/oid/spatial"
require "active_record/connection_adapters/postgis/create_connection"

module ActiveRecord  # :nodoc:
  module ConnectionAdapters  # :nodoc:
    module PostGIS  # :nodoc:
      extend ActiveSupport::Autoload

      autoload :PostGISDatabaseTasks,
        "active_record/connection_adapters/postgis/postgis_database_tasks"
    end
  end
end

::ActiveRecord::ConnectionAdapters::PostGIS.initial_setup

if defined?(::Rails::Railtie)
  load ::File.expand_path("postgis/railtie.rb", ::File.dirname(__FILE__))
end

# :startdoc:

module ActiveRecord
  module ConnectionAdapters
    class PostGISAdapter < PostgreSQLAdapter
      include PostGIS::SchemaStatements

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

      # def initialize(*args)
      def initialize(connection, logger, connection_parameters, config)
        super

        @visitor = Arel::Visitors::PostGIS.new(self)
        # copy from https://github.com/rails/rails/blob/6ece7df8d80c6d93db43878fa4c0278a0204072c/activerecord/lib/active_record/connection_adapters/postgresql_adapter.rb#L199
        if self.class.type_cast_config_to_boolean(config.fetch(:prepared_statements) { true })
          @prepared_statements = true
          @visitor.extend(DetermineIfPreparableVisitor)
        else
          @prepared_statements = false
        end
      end

      def adapter_name
        "PostGIS".freeze
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

      def quote(value, column = nil)
        if RGeo::Feature::Geometry.check_type(value)
          "'#{RGeo::WKRep::WKBGenerator.new(hex_format: true, type_format: :ewkb, emit_ewkb_srid: true).generate(value)}'"
        elsif value.is_a?(RGeo::Cartesian::BoundingBox)
          "'#{value.min_x},#{value.min_y},#{value.max_x},#{value.max_y}'::box"
        else
          super
        end
      end
    end
  end
end
