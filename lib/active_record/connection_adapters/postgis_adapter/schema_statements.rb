module ActiveRecord
  module ConnectionAdapters
    module PostGISAdapter
      module SchemaStatements
        # override
        # pass table_name to #new_column
        def columns(table_name)
          # Limit, precision, and scale are all handled by the superclass.
          column_definitions(table_name).map do |column_name, type, default, notnull, oid, fmod|
            oid = get_oid_type(oid.to_i, fmod.to_i, column_name, type)
            default_value = extract_value_from_default(oid, default)
            default_function = extract_default_function(default_value, default)
            new_column(table_name, column_name, default_value, oid, type, notnull == 'f', default_function)
          end
        end

        # override
        def new_column(table_name, column_name, default, cast_type, sql_type = nil, null = true, default_function = nil)
          # JDBC gets true/false in Rails 4, where other platforms get 't'/'f' strings.
          if null.is_a?(String)
            null = (null == 't')
          end

          column_info = spatial_column_info(table_name).get(column_name, sql_type)

          SpatialColumn.new(table_name,
                            column_name,
                            default,
                            cast_type,
                            sql_type,
                            null,
                            default_function,
                            column_info)
        end

        # override
        # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/connection_adapters/postgresql/schema_statements.rb#L533
        #
        # returns Postgresql sql type string
        # examples:
        #   "geometry(Point,4326)"
        #   "geography(Point,4326)"
        #
        # note: type alone is not enough to detect the sql type,
        # so `limit` is used to pass the additional information. :(
        #
        # type_to_sql(:geography, "Point,4326")
        # => "geography(Point,4326)"
        def type_to_sql(type, limit = nil, precision = nil, scale = nil)
          case type
          when :geometry, :geography
            "#{ type.to_s }(#{ limit })"
          else
            super
          end
        end

        # override
        def native_database_types
          # Add spatial types
          super.merge(
            geography:           "geography",
            geometry:            "geometry",
            geometry_collection: "geometry_collection",
            line_string:         "line_string",
            multi_line_string:   "multi_line_string",
            multi_point:         "multi_point",
            multi_polygon:       "multi_polygon",
            spatial:             "geometry",
            st_point:            "st_point",
            st_polygon:          "st_polygon",
          )
        end

        # override
        def create_table_definition(name, temporary, options, as = nil)
          PostGISAdapter::TableDefinition.new(native_database_types, name, temporary, options, as, self)
        end

        # memoize hash of column infos for tables
        def spatial_column_info(table_name)
          @spatial_column_info ||= {}
          @spatial_column_info[table_name.to_sym] ||= SpatialColumnInfo.new(self, table_name.to_s)
        end

        def initialize_type_map(map)
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
            )
            .each do |geo_type|
              map.register_type(geo_type) do |oid, _, sql_type|
                OID::Spatial.new(oid, sql_type)
              end
            end
        end

      end
    end
  end
end
