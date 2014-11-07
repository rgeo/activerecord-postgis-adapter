module ActiveRecord
  module ConnectionAdapters
    module PostGISAdapter
      class SchemaCreation < PostgreSQL::SchemaCreation
        private

        def visit_AddColumn(o)
          if %i[spatial geography].include?(o.type)
            # if (info = spatial_column_constructor(type.to_sym))
            #   options[:info] = info
              sql = add_spatial_column(o)
              add_column_options! sql, column_options(o)
            # end
          else
            super
          end
        end

        def add_spatial_column(o)
          # info = options[:info] || {}
          # options.merge!(o.limit) if o.limit.is_a?(::Hash)
          type = o.type.to_s.gsub('_', '').upcase
          # srid = (options[:srid] || PostGISAdapter::DEFAULT_SRID).to_i
          if o.geographic?
            type << 'Z' if o.has_z?
            type << 'M' if o.has_m?
            "ADD COLUMN #{quote_column_name(o.name)} GEOGRAPHY(#{o.type},#{o.srid})"
          else
            raise NotImplementedError
            # type = "#{type}M" if o.has_m? && !o.has_z?
            # dimensions = set_dimensions(has_m, has_z)
            # execute("SELECT AddGeometryColumn('#{quote_string(table_name)}', '#{quote_string(column_name)}', #{o.srid}, '#{quote_string(o.type)}', #{dimensions})")
            # change_column_null(table_name, column_name, false, options[:default]) if options[:null] == false
          end
        end

      end
    end
  end
end
