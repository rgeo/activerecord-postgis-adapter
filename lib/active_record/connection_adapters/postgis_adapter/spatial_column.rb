module ActiveRecord  # :nodoc:
  module ConnectionAdapters  # :nodoc:
    module PostGISAdapter  # :nodoc:
      class SpatialColumn < ConnectionAdapters::PostgreSQLColumn  # :nodoc:

        # sql_type examples:
        #   "Geometry(Point,4326)"
        #   "Geography(Point,4326)"
        # cast_type example classes:
        #   OID::Spatial
        #   OID::Integer
        def initialize(factory_settings, table_name, name, default, cast_type, sql_type = nil, null = true, opts = nil)
          @factory_settings = factory_settings
          @table_name = table_name
          @geographic = !!(sql_type =~ /geography\(/i)
          if opts
            # This case comes from an entry in the geometry_columns table
            set_geometric_type_from_name(opts[:type])
            @srid = opts[:srid].to_i
            @has_z = !!opts[:has_z]
            @has_m = !!opts[:has_m]
          elsif @geographic
            # Geographic type information is embedded in the SQL type
            @srid = 4326
            @has_z = @has_m = false
            build_from_sql_type(sql_type)
          elsif sql_type =~ /geography|geometry|point|linestring|polygon/i
            # A geometry column with no geometry_columns entry.
            # @geometric_type = geo_type_from_sql_type(sql_type)
            build_from_sql_type(sql_type)
          end
          super(name, default, cast_type, sql_type, null)
          if spatial?
            if @srid
              @limit = { srid: @srid, type: geometric_type.type_name.underscore }
              @limit[:has_z] = true if @has_z
              @limit[:has_m] = true if @has_m
              @limit[:geographic] = true if @geographic
            end
          end
        end

        attr_reader :geographic,
                    :geometric_type,
                    :has_m,
                    :has_z,
                    :limit, # override
                    :srid

        alias :geographic? :geographic
        alias :has_z? :has_z
        alias :has_m? :has_m

        def spatial?
          cast_type.respond_to?(:spatial?) && cast_type.spatial?
        end

        # TODO: delete - unused?
        def has_spatial_constraints?
          !!@srid
        end

        private

        def set_geometric_type_from_name(name)
          @geometric_type = RGeo::ActiveRecord.geometric_type_from_name(name) || RGeo::Feature::Geometry
        end

        def build_from_sql_type(sql_type)
          geo_type, @srid, @has_z, @has_m = OID::Spatial.parse_sql_type(sql_type)
          set_geometric_type_from_name(geo_type)
        end
      end
    end
  end
end
