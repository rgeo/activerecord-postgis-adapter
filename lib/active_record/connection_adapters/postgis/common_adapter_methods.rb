module ActiveRecord # :nodoc:
  module ConnectionAdapters # :nodoc:
    module PostGIS # :nodoc:
      module CommonAdapterMethods # :nodoc:
        SPATIAL_DATABASE_TYPE = {
            st_point:                { type: :st_point, has_z: false, has_m: false},
            st_point_z:              { type: :st_point, has_z: true, has_m: false },
            st_point_z_m:            { type: :st_point, has_z: true, has_m: true },
            st_polygon:              { type: :st_point, has_z: false, has_m: false },
            st_polygon_z:            { type: :st_polygon, has_z: true, has_m: true },
            st_polygon_z_m:          { type: :st_polygon, has_z: true, has_m: false },
            st_geography:            { geographic: true },
            st_geometry:             { type: :st_geometry, has_z: false, has_m: false},
            st_geometry_z:           { type: :st_geometry, has_z: true, has_m: false },
            st_geometry_z_m:         { type: :st_geometry, has_z: true, has_m: true },
            st_linestring:           { type: :st_linestring, has_z: false, has_m: false},
            st_linestring_z:         { type: :st_linestring, has_z: true, has_m: false },
            st_linestring_m:         { type: :st_linestring, has_z: false, has_m: true },
            st_linestring_z_m:       { type: :st_linestring, has_z: true, has_m: true },
            st_multi_linestring:     { type: :st_multi_linestring, has_z: false, has_m: false },
            st_multi_linestring_z:   { type: :st_multi_linestring, has_z: true, has_m: false },
            st_multi_linestring_m:   { type: :st_multi_linestring, has_z: false, has_m: true },
            st_multi_linestring_z_m: { type: :st_multi_linestring, has_z: true, has_m: true },
            st_geometry_collection:  {},
            st_multi_point:          {},
            st_multi_polygon:        {}
        }

        def self.spatial_column_constructor(name)
          SPATIAL_DATABASE_TYPE[name]
        end

        def set_rgeo_factory_settings(factory_settings)
          @rgeo_factory_settings = factory_settings
        end

        def postgis_lib_version
          @postgis_lib_version ||= select_value('SELECT PostGIS_Lib_Version()')
        rescue ActiveRecord::StatementInvalid
          ActiveRecord::Base.logger.warn 'PostGIS extension not installed'
          '0.0'
        end
      end
    end
  end
end
