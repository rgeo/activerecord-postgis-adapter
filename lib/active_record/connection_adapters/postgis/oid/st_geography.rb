module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module OID
        class STGeography < Spatial # :nodoc:
          def initialize(sql_type)
            super
            @factory = RGeo::Geographic.spherical_factory(srid: srid)
          end

          def precision
            true
          end

          alias_method :geographic?, :precision

          def srid
            4326
          end

          private
            def default_type
              'geography'
            end
        end
      end
    end
  end
end
