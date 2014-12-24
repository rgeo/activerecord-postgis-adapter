module ActiveRecord # :nodoc:
  module ConnectionAdapters # :nodoc:
    module PostGIS
      module SchemaStatements
        def columns(table_name)
          column_info = SpatialColumnInfo.new(self, quote_string(table_name.to_s))

          # Limit, precision, and scale are all handled by the superclass.
          column_definitions(table_name).map do |column_name, type, default, notnull, oid, fmod|
            oid = get_oid_type(oid.to_i, fmod.to_i, column_name, type)
            default_value = extract_value_from_default(oid, default)
            default_function = extract_default_function(default_value, default)

            # JDBC gets true/false in Rails 4.2, where other platforms get 't'/'f' strings.
            notnull = ![true, 't'].include?(notnull)

            if oid.class <= OID::Spatial
              current_info = column_info.get(column_name, type)
              new_spatial_column(table_name,column_name, default,oid,type,notnull,current_info)
            else
              new_column(column_name, default_value, oid, type, notnull, default_function)
            end
          end
        end

        # override
        def native_database_types
          # Add spatial types
          super.merge(spatial_database_types)
        end

        def new_spatial_column(table_name, column_name, default, cast_type, sql_type = nil, null = true, column_info)
          PostGISColumn.new(@rgeo_factory_settings,table_name,column_name,default,cast_type,sql_type,null,column_info)
        end

        def type_to_sql(type, limit = nil, precision = nil, scale = nil)
          if spatial_database_types.keys.include? type
            type = type.to_s.sub('st_','')
            st_type = (precision || type == 'geography') ? 'Geography' : 'Geometry'
            params = []
            params << type.camelize  unless type == 'geography'
            params << limit unless st_type == 'Geography'
            "#{st_type}(#{params.compact.join(',')})"
          else
            super
          end
        end

        def add_index_options(table_name, column_name, options = {})
          options ||= {}
          options[:using] = 'GIST' if options.delete(:spatial)
          super
        end

        # memoize hash of column infos for tables
        def spatial_column_info(table_name)
          @spatial_column_info ||= {}
          @spatial_column_info[table_name.to_sym] ||= SpatialColumnInfo.new(self, table_name.to_s)
        end

      end
    end
  end
end