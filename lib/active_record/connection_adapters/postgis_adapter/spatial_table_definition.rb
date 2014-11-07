module ActiveRecord  # :nodoc:
  module ConnectionAdapters  # :nodoc:
    module PostGISAdapter  # :nodoc:
      class TableDefinition < PostgreSQL::TableDefinition  # :nodoc:

        def initialize(types, name, temporary, options, as, adapter)
          @adapter = adapter
          @spatial_columns_hash = {}
          super(types, name, temporary, options, as)
        end

        # super: https://github.com/rails/rails/blob/master/activerecord/lib/active_record/connection_adapters/abstract/schema_definitions.rb#L320
        def new_column_definition(name, type, options)
          if (info = @adapter.spatial_column_constructor(type.to_sym))
            options[:type] ||= info[:type] || type
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
            column = super(name, type, options)
            column.spatial_type = options[:type]
            column.geographic = options[:geographic]
            column.srid = options[:srid]
            column.has_z = options[:has_z]
            column.has_m = options[:has_m]
            (column.geographic? ? @columns_hash : @spatial_columns_hash)[name] = column
          else
            column = super(name, type, options)
          end

          column
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

        def geometry(name, options = {})
          column(name, :geometry, options)
        end

        def line_string(name, options = {})
          column(name, :line_string, options)
        end

        def point(name, options = {})
          column(name, :point, options)
        end

        def polygon(name, options = {})
          column(name, :polygon, options)
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

        def spatial_type=(value)
          @spatial_type = value.to_s
        end

        def geographic?
          @geographic
        end

        def geographic=(value)
          @geographic = !!value
        end

        def srid
          if @srid
            @srid.to_i
          else
            geographic? ? 4326 : PostGISAdapter::DEFAULT_SRID
          end
        end

        def srid=(value)
          @srid = value
        end

        def has_z?
          @has_z
        end

        def has_z=(value)
          @has_z = !!value
        end

        def has_m?
          @has_m
        end

        def has_m=(value)
          @has_m = !!value
        end

      end

    end
  end
end
