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

      end
    end
  end
end
