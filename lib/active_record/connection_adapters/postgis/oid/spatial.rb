module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module OID
        class Spatial < PostgreSQLAdapter::OID::Type # :nodoc:

          def initialize(factory_generator)
            @factory_generator = factory_generator
          end

          def type_cast(value)
            return if value.nil?
            ::RGeo::WKRep::WKBParser.new(@factory_generator, support_ewkb: true).parse(value) rescue nil
          end
        end
      end
    end
  end
end
