module ActiveRecord
  module ConnectionAdapters
    module PostGISAdapter
      module OID
        class Spatial < Type::Value
          # sql_type is a string that comes from the database definition
          # examples:
          #   "geometry(Point,4326)"
          #   "geography(Point,4326)"
          #   "geometry(Polygon,4326) NOT NULL"
          #   "geometry(Geography,4326)"
          def initialize(sql_type)
            @sql_type = sql_type
            @factory_generator = RGeo::Geographic.method(:spherical_factory) if sql_type =~ /geography/
          end

          def factory_generator
            @factory_generator
          end

          def geographic?
            !!factory_generator
          end

          def spatial?
            true
          end

          def type
            geographic? ? :geography : :geometry
          end

          # support setting an RGeo object or a WKT string
          def type_cast_for_database(value)
            return if value.nil?
            geo_value = type_cast(value)

            # TODO - only valid types should be allowed
            # e.g. linestring is not valid for point column
            # raise "maybe should raise" unless RGeo::Feature::Geometry.check_type(geo_value)

            RGeo::WKRep::WKBGenerator.new(hex_format: true, type_format: :ewkb, emit_ewkb_srid: true)
              .generate(geo_value)
          end

          private

          def type_cast(value)
            return if value.nil?
            String === value ? parse_wkt(value) : value
          end

          def cast_value(value)
            return if value.nil?
            RGeo::WKRep::WKBParser.new(@factory_generator, support_ewkb: true).parse(value)
          rescue RGeo::Error::ParseError
            puts "\ncast failed!!\n\n"
            nil
          end

          # convert WKT string into RGeo object
          def parse_wkt(string)
            # factory = factory_settings.get_column_factory(table_name, column, constraints)
            factory = RGeo::ActiveRecord::RGeoFactorySettings.new
            wkt_parser(factory, string).parse(string)
          rescue RGeo::Error::ParseError
            nil
          end

          def binary?(string)
            string[0] == "\x00" || string[0] == "\x01" || string[0, 4] =~ /[0-9a-fA-F]{4}/
          end

          def wkt_parser(factory, string)
            if binary?(string)
              RGeo::WKRep::WKBParser.new(factory, support_ewkb: true)
            else
              RGeo::WKRep::WKTParser.new(factory, support_ewkt: true)
            end
          end

        end
      end
    end
  end
end
