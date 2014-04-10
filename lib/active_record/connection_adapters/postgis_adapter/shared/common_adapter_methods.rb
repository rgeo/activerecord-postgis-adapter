module ActiveRecord  # :nodoc:
  module ConnectionAdapters  # :nodoc:
    module PostGISAdapter  # :nodoc:
      SPATIAL_COLUMN_CONSTRUCTORS = ::RGeo::ActiveRecord::DEFAULT_SPATIAL_COLUMN_CONSTRUCTORS.merge(
        :geography => {:type => 'geometry', :geographic => true}
      )

      module CommonAdapterMethods  # :nodoc:
        def set_rgeo_factory_settings(factory_settings_)
          @rgeo_factory_settings = factory_settings_
        end

        def adapter_name
          PostGISAdapter::ADAPTER_NAME
        end

        def spatial_column_constructor(name_)
          PostGISAdapter::SPATIAL_COLUMN_CONSTRUCTORS[name_]
        end

        def postgis_lib_version
          @postgis_lib_version ||= select_value("SELECT PostGIS_Lib_Version()")
        end

        # http://postgis.17.x6.nabble.com/Default-SRID-td5001115.html
        def default_srid
          0
        end

        def srs_database_columns
          {:srtext_column => 'srtext', :proj4text_column => 'proj4text', :auth_name_column => 'auth_name', :auth_srid_column => 'auth_srid'}
        end

        def quote(value_, column_=nil)
          if ::RGeo::Feature::Geometry.check_type(value_)
            "'#{::RGeo::WKRep::WKBGenerator.new(:hex_format => true, :type_format => :ewkb, :emit_ewkb_srid => true).generate(value_)}'"
          elsif value_.is_a?(::RGeo::Cartesian::BoundingBox)
            "'#{value_.min_x},#{value_.min_y},#{value_.max_x},#{value_.max_y}'::box"
          else
            super
          end
        end
      end
    end
  end
end
