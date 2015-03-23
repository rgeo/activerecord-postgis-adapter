module ActiveRecord
  module ConnectionAdapters
    module PostGISAdapter
      class SpatialFactoryStore
        include Singleton

        attr_accessor :registry

        def initialize
          @registry = {}
        end

        def register(factory, attrs = {})
          registry[key(attrs)] = factory
        end

        def default(geo_type = "")
          @default || default_for_type(geo_type)
        end

        def default=(factory)
          @default = factory
        end

        def factory(attrs)
          registry[key(attrs)] || default(attrs)
        end

        private

        def default_for_type(attrs)
          if attrs[:geo_type] =~ /geography/
            RGeo::Geographic.spherical_factory(to_factory_attrs(attrs))
          else
            RGeo::ActiveRecord::RGeoFactorySettings.new
          end
        end

        def to_factory_attrs(attrs)
          attrs.slice(:srid).merge(
            has_m_coordinate: attrs[:has_m],
            has_z_coordinate: attrs[:has_z],
          )
        end

        def key(attrs)
          {
            geo_type: "geometry",
            has_m: false,
            has_z: false ,
            sql_type: "geometry",
            srid: 0,
          }.merge(attrs).hash
        end
      end
    end
  end
end
