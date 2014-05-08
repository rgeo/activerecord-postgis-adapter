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
            :spatial => {:name => 'geometry'},
            :geography => {:name => 'geography'})
        end

        def type_cast(value, column, array_member = false)
          if ::RGeo::Feature::Geometry.check_type(value)
            ::RGeo::WKRep::WKBGenerator.new(:hex_format => true, :type_format => :ewkb, :emit_ewkb_srid => true).generate(value)
          else
            super
          end
        end

        def columns(table_name, name = nil)
          # FULL REPLACEMENT. RE-CHECK ON NEW VERSIONS.
          # We needed to return a spatial column subclass.
          table_name = table_name.to_s
          spatial_info_ = spatial_column_info(table_name)
          column_definitions(table_name).collect do |col_name, type, default, notnull, oid, fmod|
            oid = type_map.fetch(oid.to_i, fmod.to_i) {
              OID::Identity.new
            }
            SpatialColumn.new(@rgeo_factory_settings,
                              table_name,
                              col_name,
                              default,
                              oid,
                              type,
                              notnull == 'f',
                              type =~ /geometry/i ? spatial_info_[col_name] : nil)
          end
        end

        def indexes(table_name, name = nil)
          # FULL REPLACEMENT. RE-CHECK ON NEW VERSIONS.
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
            index_name_ = row[0]
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

            # add info on sort order for columns (only desc order is explicitly specified, asc is the default)
            desc_order_columns_ = inddef.scan(/(\w+) DESC/).flatten
            orders = desc_order_columns_.any? ? Hash[desc_order_columns_.map {|order_column_| [order_column_, :desc]}] : {}
            where = inddef.scan(/WHERE (.+)$/).flatten[0]
            spatial = inddef =~ /using\s+gist/i && columns.size == 1 &&
              (columns.values.first[1] == 'geometry' || columns.values.first[1] == 'geography')

            if column_names.empty?
              nil
            else
              ::RGeo::ActiveRecord::SpatialIndexDefinition.new(table_name, index_name_, unique, column_names, [], orders, where, !!spatial)
            end
          end.compact
        end

        def create_table_definition(name, temporary, options, as = nil)
          # Override to create a spatial table definition
          PostGISAdapter::TableDefinition.new(native_database_types, name, temporary, options, as, self)
        end

        def create_table(table_name, options = {}, &block)
          table_name = table_name.to_s
          # Call super and snag the table definition
          table_definition = nil
          super(table_name, options) do |td|
            block.call(td) if block
            table_definition = td
          end
          table_definition.non_geographic_spatial_columns.each do |col|
            type = col.spatial_type.gsub('_', '').upcase
            has_z = col.has_z?
            has_m = col.has_m?
            type = "#{type}M" if has_m && !has_z
            dimensions_ = 2
            dimensions_ += 1 if has_z
            dimensions_ += 1 if has_m
            execute("SELECT AddGeometryColumn('#{quote_string(table_name)}', '#{quote_string(col.name.to_s)}', #{col.srid}, '#{quote_string(type)}', #{dimensions_})")
          end
        end

        def add_column(table_name, column_name, type, options = {})
          table_name = table_name.to_s
          column_name = column_name.to_s
          if (info = spatial_column_constructor(type.to_sym))
            limit = options[:limit]
            if type.to_s == 'geometry' &&
              (options[:no_constraints] || limit.is_a?(::Hash) && limit[:no_constraints])
            then
              options.delete(:limit)
              super
            else
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
                dimensions = 2
                dimensions += 1 if has_z
                dimensions += 1 if has_m
                execute("SELECT AddGeometryColumn('#{quote_string(table_name)}', '#{quote_string(column_name)}', #{srid}, '#{quote_string(type)}', #{dimensions})")
              end
            end
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

        def add_index(table_name, column_name, options = {})
          # FULL REPLACEMENT. RE-CHECK ON NEW VERSIONS.
          # We have to fully-replace because of the gist_clause.
          options ||= {}
          gist_clause = options.delete(:spatial) ? ' USING GIST' : ''
          index_name, index_type, index_columns, index_options = add_index_options(table_name, column_name, options)
          execute "CREATE #{index_type} INDEX #{quote_column_name(index_name)} ON #{quote_table_name(table_name)}#{gist_clause} (#{index_columns})#{index_options}"
        end

        def spatial_column_info(table_name)
          info = query("SELECT f_geometry_column,coord_dimension,srid,type FROM geometry_columns WHERE f_table_name='#{quote_string(table_name.to_s)}'")
          result = {}
          info.each do |row|
            name = row[0]
            type = row[3]
            dimension = row[1].to_i
            has_m = !!(type =~ /m$/i)
            type.sub!(/m$/, '')
            has_z = dimension > 3 || dimension == 3 && !has_m
            result[name] = {
              :name => name,
              :type => type,
              :dimension => dimension,
              :srid => row[2].to_i,
              :has_z => has_z,
              :has_m => has_m,
            }
          end
          result
        end

      end
    end
  end
end
