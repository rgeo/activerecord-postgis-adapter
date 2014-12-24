module ActiveRecord # :nodoc:
  module ConnectionAdapters # :nodoc:
    module PostGIS # :nodoc:
      class ColumnDefinition < ActiveRecord::ConnectionAdapters::PostgreSQL::ColumnDefinition
        attr_accessor :geographic, :has_m, :has_z, :srid, :spatial_type
        alias_method :geographic?, :geographic
        alias_method :has_z?, :has_z
        alias_method :has_m?, :has_m
        # Spatial columns should never be used as primary key
        def primary_key?
          false
        end

        def srid
          geographic? ? 4326 : @srid.to_i
        end
       end

      class TableDefinition < ConnectionAdapters::PostgreSQL::TableDefinition # :nodoc:

        def initialize(types, name, temporary, options, as = nil)
          super(types, name, temporary, options, as)
          @spatial_columns_hash = {}
        end


        def new_column_definition(name, type, options)
          if constructor = CommonAdapterMethods.spatial_column_constructor(type)
            type = constructor[:type] || type
            column = super(name, type, options)
            column.spatial_type = constructor[:type] || options[:type]
            column.precision = column.geographic = constructor[:geographic]  || options[:geographic] || options[:precision]
            column.limit = column.srid = column.geographic ? 4326 :  (options[:srid] || options[:limit]).to_i
            column.has_z = constructor[:has_z] || options[:has_z]
            column.has_m = constructor[:has_m] || options[:has_m]
            @spatial_columns_hash[name] = column
          else
            super(name, type, options)
          end
        end

        def st_geography(name, options = {})
          column(name, :st_geography, options)
        end

        def st_geometry(name, options = {})
          column(name, :st_geometry, options)
        end

        def st_geometry_z(name, options = {})
          column(name, :st_geometry_z, options)
        end

        def st_geometry_m(name, options = {})
          column(name, :st_geometry_m, options)
        end

        def st_geometry_z_m(name, options = {})
          column(name, :st_geometry_z_m, options)
        end

        def st_point(name, options = {})
          column(name, :st_point, options)
        end

        def st_point_z(name, options = {})
          column(name, :st_point_z, options)
        end

        def st_point_z_m(name, options = {})
          column(name, :st_point_z_m, options)
        end

        def st_linestring(name, options = {})
          column(name, :st_line_string, options)
        end

        def st_linestring_z(name, options = {})
          column(name, :st_line_string_z, options)
        end

        def st_linestring_m(name, options = {})
          column(name, :st_line_string_m, options)
        end

        def st_linestring_z_m(name, options = {})
          column(name, :st_line_string_z_m, options)
        end

        def st_polygon(name, options = {})
          column(name, :st_polygon, options)
        end

        def st_polygon_z(name, options = {})
          column(name, :st_polygon_z, options)
        end

        def st_polygon_m(name, options = {})
          column(name, :st_polygon_m, options)
        end

        def st_polygon_z_m(name, options = {})
          column(name, :st_polygon_z_m, options)
        end

        def st_geometry_collection(name, options = {})
          column(name, :st_geometry_collection, options)
        end

        def st_geometry_collection_z(name, options = {})
          column(name, :st_geometry_collection_z, options)
        end

        def st_geometry_collection_m(name, options = {})
          column(name, :st_geometry_collection_m, options)
        end

        def st_geometry_collection_z_m(name, options = {})
          column(name, :st_geometry_collection_z_m, options)
        end

        def st_multi_line_string(name, options = {})
          column(name, :st_multi_line_string, options)
        end

        def st_multi_line_string_z(name, options = {})
          column(name, :st_multi_line_string_z, options)
        end

        def st_multi_line_string_m(name, options = {})
          column(name, :st_multi_line_string_m, options)
        end

        def st_multi_line_string_z_m(name, options = {})
          column(name, :st_multi_line_string_z_m, options)
        end

        def st_multi_point(name, options = {})
          column(name, :st_multi_point, options)
        end

        def st_multi_point_z(name, options = {})
          column(name, :st_multi_point_z, options)
        end

        def st_multi_point_m(name, options = {})
          column(name, :st_multi_point_m, options)
        end

        def st_multi_point_z_m(name, options = {})
          column(name, :st_multi_point_z_m, options)
        end

        def st_multi_polygon(name, options = {})
          column(name, :st_multi_polygon, options)
        end

        def st_multi_polygon_z(name, options = {})
          column(name, :st_multi_polygon_z, options)
        end

        def st_multi_polygon_m(name, options = {})
          column(name, :st_multi_polygon_m, options)
        end

        def st_multi_polygon_z_m(name, options = {})
          column(name, :st_multi_polygon_z_m, options)
        end

        private
          def create_column_definition(name, type)
            if CommonAdapterMethods.spatial_column_constructor(type).nil?
              PostgreSQL::ColumnDefinition.new(name, type)
            else
              PostGIS::ColumnDefinition.new(name, type)
            end
          end
      end
    end
  end
end
