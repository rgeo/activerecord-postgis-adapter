module ActiveRecord  # :nodoc:
  module ConnectionAdapters  # :nodoc:
    module PostGIS  # :nodoc:
      class TableDefinition < PostgreSQL::TableDefinition  # :nodoc:
        include ColumnMethods

        # super: https://github.com/rails/rails/blob/master/activerecord/lib/active_record/connection_adapters/abstract/schema_definitions.rb
        def new_column_definition(name, type, options)
          if (info = PostGISAdapter.spatial_column_options(type.to_sym))
            if (limit = options.delete(:limit))
              options.merge!(limit) if limit.is_a?(::Hash)
            end

            geo_type = ColumnDefinition.geo_type(options[:type] || type || info[:type])
            base_type = info[:type] || (options[:geographic] ? :geography : :geometry)

            # puts name.dup << " - " << type.to_s << " - " << options.to_s << " :: " << geo_type.to_s << " - " << base_type.to_s

            if options[:geographic]
              options[:limit] = ColumnDefinition.options_to_limit(geo_type, options)
            end
            column = super(name, base_type, options)
            column.spatial_type = geo_type
            column.geographic = options[:geographic]
            column.srid = options[:srid]
            column.has_z = options[:has_z]
            column.has_m = options[:has_m]
          else
            column = super(name, type, options)
          end

          column
        end

        private

        def create_column_definition(name, type)
          if PostGISAdapter.spatial_column_options(type.to_sym)
            PostGIS::ColumnDefinition.new(name, type)
          else
            super
          end
        end
      end

      class ColumnDefinition < PostgreSQL::ColumnDefinition
        # needs to accept the spatial type? or figure out from limit ?

        def self.options_to_limit(type, options = {})
          spatial_type = geo_type(type)
          spatial_type << "Z" if options[:has_z]
          spatial_type << "M" if options[:has_m]
          spatial_type << ",#{ options[:srid] || 4326 }"
          spatial_type
        end

        # limit is how column options are passed to #type_to_sql
        # returns: "Point,4326"
        def limit
          "".tap do |value|
            value << self.class.geo_type(spatial_type)
            value << "Z" if has_z?
            value << "M" if has_m?
            value << ",#{ srid }"
          end
        end

        def self.geo_type(type = "GEOMETRY")
          g_type = type.to_s.delete("_").upcase
          return "POINT" if g_type == "STPOINT"
          return "POLYGON" if g_type == "STPOLYGON"
          g_type
        end

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
