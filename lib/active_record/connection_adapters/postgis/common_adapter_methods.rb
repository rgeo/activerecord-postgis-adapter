module ActiveRecord  # :nodoc:
  module ConnectionAdapters  # :nodoc:
    module PostGIS  # :nodoc:
      SPATIAL_COLUMN_CONSTRUCTORS = ::RGeo::ActiveRecord::DEFAULT_SPATIAL_COLUMN_CONSTRUCTORS.merge(
        geography: { type: 'geometry', geographic: true }
      )

      # http://postgis.17.x6.nabble.com/Default-SRID-td5001115.html
      DEFAULT_SRID = 0

      module CommonAdapterMethods  # :nodoc:
        def set_rgeo_factory_settings(factory_settings)
          @rgeo_factory_settings = factory_settings
        end

        def adapter_name
          PostGIS::ADAPTER_NAME
        end

        def spatial_column_constructor(name)
          PostGIS::SPATIAL_COLUMN_CONSTRUCTORS[name]
        end

        def postgis_lib_version
          @postgis_lib_version ||= select_value("SELECT PostGIS_Lib_Version()")
        end

        def default_srid
          DEFAULT_SRID
        end

        def srs_database_columns
          {
            auth_name_column: 'auth_name',
            auth_srid_column: 'auth_srid',
            proj4text_column: 'proj4text',
            srtext_column:    'srtext',
          }
        end

        def quote(value, column=nil)
          if ::RGeo::Feature::Geometry.check_type(value)
            "'#{::RGeo::WKRep::WKBGenerator.new(hex_format: true, type_format: :ewkb, emit_ewkb_srid: true).generate(value)}'"
          elsif value.is_a?(::RGeo::Cartesian::BoundingBox)
            "'#{value.min_x},#{value.min_y},#{value.max_x},#{value.max_y}'::box"
          else
            super
          end
        end
      end
    end
  end
end
