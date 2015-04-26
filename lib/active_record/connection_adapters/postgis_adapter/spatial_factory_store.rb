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

        def default(attrs = {})
          @default || default_for_attrs(attrs)
        end

        def default=(factory)
          @default = factory
        end

        def factory(attrs)
          registry[key(attrs)] || default(attrs)
        end

        def clear
          @registry = {}
        end

        private

        def default_for_attrs(attrs)
          if attrs[:sql_type] =~ /geography/
            RGeo::Geographic.spherical_factory(to_factory_attrs(attrs))
          else
            RGeo::ActiveRecord::RGeoFactorySettings.new
          end
        end

        def to_factory_attrs(attrs)
          {
            has_m_coordinate: attrs[:has_m],
            has_z_coordinate: attrs[:has_z],
            srid:             (attrs[:srid] || 0),
          }
        end

        def key(attrs)
          {
            geo_type: "geometry",
            has_m:    false,
            has_z:    false,
            sql_type: "geometry",
            srid:     0,
          }.merge(attrs).hash
        end
      end
    end
  end
end
