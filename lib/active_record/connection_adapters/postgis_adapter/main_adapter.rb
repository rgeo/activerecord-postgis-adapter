module ActiveRecord  # :nodoc:
  module ConnectionAdapters  # :nodoc:
    module PostGISAdapter  # :nodoc:
      class MainAdapter < PostgreSQLAdapter  # :nodoc:
        def initialize(*args)
          # Overridden to change the visitor
          super
          @visitor = ::Arel::Visitors::PostGIS.new(self)
        end

        include PostGISAdapter::CommonAdapterMethods

        @@native_database_types = nil

        def native_database_types
          # Overridden to add the :spatial type
          @@native_database_types ||= super.merge(
            geography: { name: 'geography' },
            spatial:   { name: 'geometry' },
          )
        end

        def type_cast(value, column, array_member = false)
          if ::RGeo::Feature::Geometry.check_type(value)
            ::RGeo::WKRep::WKBGenerator.new(hex_format: true, type_format: :ewkb, emit_ewkb_srid: true).generate(value)
          else
            super
          end
        end

        # FULL REPLACEMENT. RE-CHECK ON NEW VERSIONS
        # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/connection_adapters/postgresql/schema_statements.rb
        def columns(table_name, name = nil)
          column_info = SpatialColumnInfo.new(self, quote_string(table_name.to_s))
          # Limit, precision, and scale are all handled by the superclass.
          column_definitions(table_name).map do |column_name, type, default, notnull, oid, fmod|
            # JDBC gets true/false in Rails 4, where other platforms get
            # 't'/'f' strings.
            if(notnull.is_a?(String))
              notnull = (notnull == 't')
            end

            oid = column_type_map.fetch(oid.to_i, fmod.to_i) { OID::Identity.new }
            SpatialColumn.new(@rgeo_factory_settings,
                              table_name,
                              column_name,
                              default,
                              oid,
                              type,
                              !notnull,
                              column_info.get(column_name, type))
          end
        end

        # FULL REPLACEMENT. RE-CHECK ON NEW VERSIONS
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
              ::RGeo::ActiveRecord::SpatialIndexDefinition.new(table_name, index_name, unique, column_names, [], orders, where, !!spatial)
            end
          end.compact
        end

        def create_table_definition(name, temporary, options, as = nil)
          # Override to create a spatial table definition
          if ActiveRecord::VERSION::STRING > '4.1'
            PostGISAdapter::TableDefinition.new(native_database_types, name, temporary, options, as, self)
          else
            PostGISAdapter::TableDefinition.new(native_database_types, name, temporary, options, self)
          end
        end

        def create_table(table_name, options = {}, &block)
          table_name = table_name.to_s
          # Call super and snag the table definition
          table_definition = nil
          non_geographic_spatial_indexes = {}
          super(table_name, options) do |td|
            block.call(td) if block
            if td.non_geographic_spatial_columns.any?
              non_geographic_spatial_indexes = td.indexes.inject({}) do |indexes, (column_names, index_options)|
                spatial_indexes = column_names.select do |column_name|
                  td.non_geographic_spatial_columns.select{ |col| col.name == column_name }.any?
                end
                indexes[column_names] = index_options if spatial_indexes.any?
                indexes
              end
              non_geographic_spatial_indexes.each_key { |column_names| td.indexes.delete(column_names) }
            end
            table_definition = td
          end
          table_definition.non_geographic_spatial_columns.each do |col|
            options = {
              default: col.default,
              has_m: col.has_m?,
              has_z: col.has_z?,
              null: col.null,
              srid:  col.srid,
              type:  col.spatial_type,
            }
            column_name = col.name.to_s
            type = col.spatial_type

            add_spatial_column(table_name, column_name, type, options)
          end
          non_geographic_spatial_indexes.each do |column_names, index_options|
            add_index table_name, column_names, index_options
          end
        end

        def add_column(table_name, column_name, type, options = {})
          table_name = table_name.to_s
          column_name = column_name.to_s
          if (info = spatial_column_constructor(type.to_sym))
            options[:info] = info
            add_spatial_column(table_name, column_name, type, options)
          else
            super
          end
        end

        def remove_column(table_name, column_name, type = nil, options = {})
          table_name = table_name.to_s
          column_name = column_name.to_s
          spatial_info = spatial_column_info(table_name)
          if spatial_info.include?(column_name)
            execute("SELECT DropGeometryColumn('#{quote_string(table_name)}','#{quote_string(column_name)}')")
          else
            super
          end
        end

        # FULL REPLACEMENT. RE-CHECK ON NEW VERSIONS
        # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/connection_adapters/postgresql/schema_statements.rb
        def add_index(table_name, column_name, options = {})
          # We have to fully replace to add the gist clause.
          options ||= {} # in case nil explicitly passed
          gist = options.delete(:spatial)
          index_name, index_type, index_columns, index_options, index_algorithm, index_using = add_index_options(table_name, column_name, options)
          index_using = 'USING GIST' if gist
          execute "CREATE #{index_type} INDEX #{index_algorithm} #{quote_column_name(index_name)} ON #{quote_table_name(table_name)} #{index_using} (#{index_columns})#{index_options}"
        end

        def spatial_column_info(table_name)
          SpatialColumnInfo.new(self, quote_string(table_name.to_s)).all
        end

        private

        def add_spatial_column(table_name, column_name, type, options)
          limit = options[:limit]
          info = options[:info] || {}
          options.merge!(limit) if limit.is_a?(::Hash)
          type = (options[:type] || info[:type] || type).to_s.gsub('_', '').upcase
          has_z = options[:has_z]
          has_m = options[:has_m]
          srid = (options[:srid] || PostGISAdapter::DEFAULT_SRID).to_i
          if options[:geographic]
            type << 'Z' if has_z
            type << 'M' if has_m
            execute("ALTER TABLE #{quote_table_name(table_name)} ADD COLUMN #{quote_column_name(column_name)} GEOGRAPHY(#{type},#{srid})")
            change_column_default(table_name, column_name, options[:default]) if options_include_default?(options)
            change_column_null(table_name, column_name, false, options[:default]) if options[:null] == false
          else
            type = "#{type}M" if has_m && !has_z
            dimensions = set_dimensions(has_m, has_z)
            execute("SELECT AddGeometryColumn('#{quote_string(table_name)}', '#{quote_string(column_name)}', #{srid}, '#{quote_string(type)}', #{dimensions})")
            change_column_null(table_name, column_name, false, options[:default]) if options[:null] == false
          end
        end

        def column_type_map
          if defined?(type_map) # ActiveRecord 4.1+
            type_map
          else # ActiveRecord 4.0.x
            OID::TYPE_MAP
          end
        end

        def set_dimensions(has_m, has_z)
          dimensions = 2
          dimensions += 1 if has_z
          dimensions += 1 if has_m
          dimensions
        end
      end
    end
  end
end
