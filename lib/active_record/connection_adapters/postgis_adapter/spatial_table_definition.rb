module ActiveRecord  # :nodoc:
  module ConnectionAdapters  # :nodoc:
    module PostGISAdapter  # :nodoc:
      class TableDefinition < PostgreSQL::TableDefinition  # :nodoc:

        def initialize(types, name, temporary, options, as, adapter)
          @adapter = adapter
          @spatial_columns_hash = {}
          super(types, name, temporary, options, as)
        end

        # * `:geometry` -- Any geometric type
        # * `:point` -- Point data
        # * `:line_string` -- LineString data
        # * `:polygon` -- Polygon data
        # * `:geometry_collection` -- Any collection type
        # * `:multi_point` -- A collection of Points
        # * `:multi_line_string` -- A collection of LineStrings
        # * `:multi_polygon` -- A collection of Polygons

        # super: https://github.com/rails/rails/blob/master/activerecord/lib/active_record/connection_adapters/abstract/schema_definitions.rb#L320
        def new_column_definition(name, type, options)
          if (info = MainAdapter.spatial_column_options(type.to_sym))
            options[:type] = info[:type] || type
            type = options[:type]

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
          raise "You must set a type. For example: 't.spatial type: :geo_point'" unless options[:type]
          column(name, options[:type], options)
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

        def geo_point(name, options = {})
          column(name, :point, options)
        end

        def polygon(name, options = {})
          column(name, :polygon, options)
        end

        private

        def create_column_definition(name, type)
          if MainAdapter.spatial_column_options(type.to_sym)
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
