module ActiveRecord  # :nodoc:
  module ConnectionAdapters  # :nodoc:
    module PostGISAdapter  # :nodoc:
      class TableDefinition < ConnectionAdapters::PostgreSQL::TableDefinition  # :nodoc:

        if ActiveRecord::VERSION::STRING > '4.1'
          def initialize(types, name, temporary, options, as, base)
            @base = base
            @spatial_columns_hash = {}
            super(types, name, temporary, options, as)
          end
        else
          def initialize(types, name, temporary, options, base)
            @base = base
            @spatial_columns_hash = {}
            super(types, name, temporary, options)
          end
        end

        def column(name, type, options={})
          if (info = @base.spatial_column_constructor(type.to_sym))
            type = options[:type] || info[:type] || type
            if type.to_s == 'geometry' && (options[:no_constraints] || options[:limit].is_a?(::Hash) && options[:limit][:no_constraints])
              options.delete(:limit)
            else
              options[:type] = type
              type = :spatial
            end
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
            if primary_key_column_name == name
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

        def create_column_definition(name, type)
          if type == :spatial || type == :geography
            PostGISAdapter::ColumnDefinition.new(name, type)
          else
            super
          end
        end

        def non_geographic_spatial_columns
          @spatial_columns_hash.values
        end

      end

      class ColumnDefinition < ConnectionAdapters::ColumnDefinition  # :nodoc:

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
