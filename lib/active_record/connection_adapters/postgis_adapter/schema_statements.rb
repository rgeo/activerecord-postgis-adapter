module ActiveRecord
  module ConnectionAdapters
    module PostGISAdapter
      # note: type_to_sql receives type, which is not enough to detect the sql type:
      # :geo_point => geometry(Point, 4326) OR geography(Point, 4326)

      module SchemaStatements
        # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/connection_adapters/postgresql/schema_statements.rb
        def indexes(table_name, name = nil)
          result = query(<<-SQL, 'SCHEMA')
            SELECT distinct i.relname, d.indisunique, d.indkey, pg_get_indexdef(d.indexrelid), t.oid
            FROM pg_class t
            INNER JOIN pg_index d ON t.oid = d.indrelid
            INNER JOIN pg_class i ON d.indexrelid = i.oid
            WHERE i.relkind = 'i'
              AND d.indisprimary = 'f'
              AND t.relname = '#{table_name}'
              AND i.relnamespace IN (SELECT oid FROM pg_namespace WHERE nspname = ANY (current_schemas(false)) )
            ORDER BY i.relname
          SQL

          result.map do |row|
            index_name = row[0]
            unique = row[1] == 't'
            indkey = row[2].split(" ")
            inddef = row[3]
            oid = row[4]

            columns = query(<<-SQL, "SCHEMA")
              SELECT a.attnum, a.attname, t.typname
                FROM pg_attribute a, pg_type t
              WHERE a.attrelid = #{oid}
                AND a.attnum IN (#{indkey.join(",")})
                AND a.atttypid = t.oid
            SQL
            columns = columns.inject({}){ |h, r| h[r[0].to_s] = [r[1], r[2]]; h }
            column_names = columns.values_at(*indkey).compact.map{ |a| a[0] }

            unless column_names.empty?
              # add info on sort order for columns (only desc order is explicitly specified, asc is the default)
              desc_order_columns = inddef.scan(/(\w+) DESC/).flatten
              orders = desc_order_columns.any? ? Hash[desc_order_columns.map {|order_column| [order_column, :desc]}] : {}
              where = inddef.scan(/WHERE (.+)$/).flatten[0]
              # using = inddef.scan(/USING (.+?) /).flatten[0].to_sym

              spatial = inddef =~ /using\s+gist/i &&
                        columns.size == 1 &&
                        %w[geometry geography].include?(columns.values.first[1])

              # IndexDefinition.new(table_name, index_name, unique, column_names, [], orders, where, nil, using)
              RGeo::ActiveRecord::SpatialIndexDefinition.new(table_name, index_name, unique, column_names, [], orders, where, !!spatial)
            end
          end.compact
        end

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

          SpatialColumn.new(@rgeo_factory_settings,
                            table_name,
                            column_name,
                            default,
                            cast_type,
                            sql_type,
                            null,
                            column_info)
        end

        # override
        # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/connection_adapters/abstract/schema_statements.rb
        def add_index_options(table_name, column_name, options = {})
          options ||= {}
          options[:using] = "GIST" if options.delete(:spatial)
          super
        end

        # override
        # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/connection_adapters/postgresql/schema_statements.rb#L533
        # returns "geometry(Point, 4326)" or "geography(Point, 4326)"
        def type_to_sql(type, limit = nil, precision = nil, scale = nil)
          case type
          when :geometry, :geography, :spatial, :geo_point
            "#{ type.to_s }(#{ limit })"
          else
            super
          end
        end

        # override
        def native_database_types
          # Add spatial types
          super.merge(
            geo_point:           "geo_point",
            geo_polygon:         "geo_polygon",
            geography:           "geography",
            geometry:            "geometry",
            geometry_collection: "geometry_collection",
            line_string:         "line_string",
            multi_line_string:   "multi_line_string",
            multi_point:         "multi_point",
            multi_polygon:       "multi_polygon",
            spatial:             "geometry",
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
            geo_point
            geo_polygon
            geography
            geometry
            geometry_collection
            line_string
            multi_line_string
            multi_point
            multi_polygon
            )
            .each do |geo_type|
              map.register_type(geo_type) do |_, _, sql_type|
                OID::Spatial.new(sql_type)
              end
            end
        end

      end
    end
  end
end
