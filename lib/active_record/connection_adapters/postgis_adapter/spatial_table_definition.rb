module ActiveRecord  # :nodoc:
  module ConnectionAdapters  # :nodoc:
    module PostGISAdapter  # :nodoc:
      class TableDefinition < PostgreSQL::TableDefinition  # :nodoc:

        def initialize(types, name, temporary, options, as, adapter)
          @adapter = adapter
          @spatial_columns_hash = {}
          super(types, name, temporary, options, as)
        end

        def column(name, type, options = {})
          if (info = @adapter.spatial_column_constructor(type.to_sym))
            type = options[:type] || info[:type] || type
            options[:type] = type
            type = :spatial
          end
          if type == :spatial
            if (limit = options.delete(:limit))
              options.merge!(limit) if limit.is_a?(::Hash)
            end
            if options[:geographic]
              type = :geography
              spatial_type = (options[:type] || 'geometry').to_s.upcase.gsub('_', '')
              spatial_type << 'Z' if options[:has_z]
              spatial_type << 'M' if options[:has_m]
              options[:limit] = "#{spatial_type},#{options[:srid] || 4326}"
            end
            name = name.to_s
            if @columns_hash[name] && @columns_hash[name].primary_key? == name
              raise ArgumentError, "you can't redefine the primary key column '#{name}'. To define a custom primary key, pass { id: false } to create_table."
            end
            column = new_column_definition(name, type, options)
            column.set_spatial_type(options[:type])
            column.set_geographic(options[:geographic])
            column.set_srid(options[:srid])
            column.set_has_z(options[:has_z])
            column.set_has_m(options[:has_m])
            (column.geographic? ? @columns_hash : @spatial_columns_hash)[name] = column
          else
            super(name, type, options)
          end
          self
        end

        def non_geographic_spatial_columns
          @spatial_columns_hash.values
        end

        def spatial(name, options = {})
          column(name, :spatial, options)
        end

        def geography(name, options = {})
          column(name, :geography, options)
        end

        private

        def create_column_definition(name, type)
          if %i[spatial geography].include?(type)
            PostGISAdapter::ColumnDefinition.new(name, type)
          else
            super
          end
        end
      end

      class ColumnDefinition < PostgreSQL::ColumnDefinition  # :nodoc:

        def spatial_type
          @spatial_type
        end

        def geographic?
          @geographic
        end

        def srid
          if @srid
            @srid.to_i
          else
            geographic? ? 4326 : PostGISAdapter::DEFAULT_SRID
          end
        end

        def has_z?
          @has_z
        end

        def has_m?
          @has_m
        end

        def set_geographic(value)
          @geographic = !!value
        end

        def set_spatial_type(value)
          @spatial_type = value.to_s
        end

        def set_srid(value)
          @srid = value
        end

        def set_has_z(value)
          @has_z = !!value
        end

        def set_has_m(value)
          @has_m = !!value
        end

      end

    end
  end
end
