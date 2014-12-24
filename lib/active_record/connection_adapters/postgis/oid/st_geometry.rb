module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module OID
        class STGeometry < Spatial # :nodoc:
          def initialize(sql_type)
            super
            @factory = RGeo::Geos.factory(srid: srid)
          end

          private
            def default_type
              'geometry'
            end
        end
      end
    end
  end
end
