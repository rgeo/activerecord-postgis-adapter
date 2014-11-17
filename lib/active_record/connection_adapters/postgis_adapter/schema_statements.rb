module ActiveRecord
  module ConnectionAdapters
    module PostGISAdapter
      class SchemaCreation < PostgreSQL::SchemaCreation
        private

        def visit_AddColumn(o)
          if %i[spatial geography].include?(o.type)
            # if (info = spatial_column_options(type.to_sym))
            #   options[:info] = info
              sql = add_spatial_column(o)
              add_column_options! sql, column_options(o)
            # end
          else
            super
          end
        end
      end

      module SchemaStatements

        # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/connection_adapters/abstract/schema_statements.rb
        # def create_table(table_name, options = {})
        #   table_name = table_name.to_s
        #   # Call super and snag the table definition
        #   table_definition = nil
        #   super(table_name, options) do |td|
        #     yield(td) if block_given?
        #     table_definition = td
        #   end
        #   table_definition.non_geographic_spatial_columns.each do |col|
        #     options = {
        #       default: col.default,
        #       has_m: col.has_m?,
        #       has_z: col.has_z?,
        #       null: col.null,
        #       srid:  col.srid,
        #       type:  col.spatial_type,
        #     }
        #     column_name = col.name.to_s
        #     type = col.spatial_type
        #
        #     add_spatial_column(table_name, column_name, type, options)
        #   end
        # end

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

          column_info = SpatialColumnInfo.new(self, quote_string(table_name.to_s)).get(column_name, sql_type)

          SpatialColumn.new(@rgeo_factory_settings,
                            table_name,
                            column_name,
                            default,
                            cast_type,
                            sql_type,
                            !null,
                            column_info)
        end

        # super uses an "alter table" statement.
        # we may use a PostGIS procedure instead
        def add_column(table_name, column_name, type, options = {})
          if (info = spatial_column_options(type.to_sym))
            options[:info] = info
            add_spatial_column table_name, column_name, type, options
          else
            super
          end
        end

        # override
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

        # override
        # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/connection_adapters/abstract/schema_statements.rb
        def add_index_options(table_name, column_name, options = {})
          options ||= {}
          options[:using] = "GIST" if options.delete(:spatial)
          super table_name, column_name, options
        end

        def spatial_column_info(table_name)
          SpatialColumnInfo.new(self, quote_string(table_name.to_s)).all
        end

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

        def set_dimensions(has_m, has_z)
          dimensions = 2
          dimensions += 1 if has_z
          dimensions += 1 if has_m
          dimensions
        end

        def initialize_type_map(m)
          super

          m.register_type 'geometry' do
            OID::Spatial.new
          end

          m.register_type 'geography' do
            OID::Spatial.new(factory_generator: ::RGeo::Geographic.method(:spherical_factory))
          end
        end


        # def add_spatial_column(o)
        #   # info = options[:info] || {}
        #   # options.merge!(o.limit) if o.limit.is_a?(::Hash)
        #   type = o.type.to_s.gsub('_', '').upcase
        #   # srid = (options[:srid] || PostGISAdapter::DEFAULT_SRID).to_i
        #   if o.geographic?
        #     type << 'Z' if o.has_z?
        #     type << 'M' if o.has_m?
        #     "ADD COLUMN #{quote_column_name(o.name)} GEOGRAPHY(#{o.type},#{o.srid})"
        #   else
        #     raise NotImplementedError
        #     # type = "#{type}M" if o.has_m? && !o.has_z?
        #     # dimensions = set_dimensions(has_m, has_z)
        #     # execute("SELECT AddGeometryColumn('#{quote_string(table_name)}', '#{quote_string(column_name)}', #{o.srid}, '#{quote_string(o.type)}', #{dimensions})")
        #     # change_column_null(table_name, column_name, false, options[:default]) if options[:null] == false
        #   end
        # end

      end
    end
  end
end
