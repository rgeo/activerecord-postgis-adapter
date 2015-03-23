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

        def default
          @default || RGeo::ActiveRecord::RGeoFactorySettings.new
        end

        def default=(factory)
          @default = factory
        end

        def factory(attrs)
          registry[key(attrs)] || default
        end

        private

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
