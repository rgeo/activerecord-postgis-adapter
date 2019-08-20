# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module SchemaStatements
        # override
        # https://github.com/rails/rails/blob/6-0-stable/activerecord/lib/active_record/connection_adapters/postgresql/schema_statements.rb#L624
        # Create a SpatialColumn instead of a PostgreSQL::Column
        def new_column_from_field(table_name, field)
          column_name, type, default, notnull, oid, fmod, collation, comment = field
          type_metadata = fetch_type_metadata(column_name, type, oid.to_i, fmod.to_i)
          default_value = extract_value_from_default(default)
          default_function = extract_default_function(default_value, default)

          serial =
            if (match = default_function&.match(/\Anextval\('"?(?<sequence_name>.+_(?<suffix>seq\d*))"?'::regclass\)\z/))
              sequence_name_from_parts(table_name, column_name, match[:suffix]) == match[:sequence_name]
            end

          # {:dimension=>2, :has_m=>false, :has_z=>false, :name=>"latlon", :srid=>0, :type=>"GEOMETRY"}
          spatial = spatial_column_info(table_name).get(column_name, type_metadata.sql_type)

          SpatialColumn.new(
            column_name,
            default_value,
            type_metadata,
            !notnull,
            default_function,
            collation: collation,
            comment: comment.presence,
            serial: serial,
            spatial: spatial
          )
        end

        # override
        # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/connection_adapters/postgresql/schema_statements.rb#L523
        #
        # returns Postgresql sql type string
        # examples:
        #   "geometry(Point,4326)"
        #   "geography(Point,4326)"
        #
        # note: type alone is not enough to detect the sql type,
        # so `limit` is used to pass the additional information. :(
        #
        # type_to_sql(:geography, limit: "Point,4326")
        # => "geography(Point,4326)"
        def type_to_sql(type, limit: nil, precision: nil, scale: nil, array: nil, **)
          case type.to_s
          when "geometry", "geography"
            "#{type}(#{limit})"
          else
            super
          end
        end

        # override
        def native_database_types
          # Add spatial types
          super.merge(
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
          )
        end

        # override
        def create_table_definition(*args)
          PostGIS::TableDefinition.new(self, *args)
        end

        # memoize hash of column infos for tables
        def spatial_column_info(table_name)
          @spatial_column_info ||= {}
          @spatial_column_info[table_name.to_sym] ||= SpatialColumnInfo.new(self, table_name.to_s)
        end

        def initialize_type_map(map = type_map)
          super

          %w(
            geography
            geometry
            geometry_collection
            line_string
            multi_line_string
            multi_point
            multi_polygon
            st_point
            st_polygon
          ).each do |geo_type|
            map.register_type(geo_type) do |oid, _, sql_type|
              OID::Spatial.new(oid, sql_type)
            end
          end
        end
      end
    end
  end
end
