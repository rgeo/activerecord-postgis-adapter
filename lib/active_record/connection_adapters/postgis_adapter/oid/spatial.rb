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
          def initialize(oid, sql_type)
            @geo_type, @srid, @has_z, @has_m = self.class.parse_sql_type(sql_type)
            if oid =~ /geography/
              factory_opts = {srid: (@srid || 4326)}
              factory_opts[:has_z_coordinate] = @has_z
              factory_opts[:has_m_coordinate] = @has_m
              @factory_generator = RGeo::Geographic.spherical_factory(factory_opts)
            end
          end

          # sql_type: geometry, geometry(Point), geometry(Point,4326), ...
          #
          # returns [geo_type, srid, has_z, has_m]
          #   geo_type: geography, geometry, point, line_string, polygon, ...
          #   srid:     1234
          #   has_z:    false
          #   has_m:    false
          def self.parse_sql_type(sql_type)
            geo_type, srid, has_z, has_m = nil, 0, false, false

            if (sql_type =~ /[geography,geography]\((.*)\)$/i)
              # geometry(Point,4326)
              params = $1.split(',')
              if params.size > 1
                if params.first =~ /([a-z]+[^zm])(z?)(m?)/i
                  has_z = $2.length > 0
                  has_m = $3.length > 0
                  geo_type = $1
                end
                if params.last =~ /(\d+)/
                  srid = $1.to_i
                end
              else
                # geometry(Point)
                geo_type = params[0]
              end
            else
              # geometry
              geo_type = sql_type
            end
            [geo_type, srid, has_z, has_m]
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
            nil
          end

          # convert WKT string into RGeo object
          def parse_wkt(string)
            # factory = factory_settings.get_column_factory(table_name, column, constraints)
            factory = @factory_generator || RGeo::ActiveRecord::RGeoFactorySettings.new
            wkt_parser(factory, string).parse(string)
          rescue RGeo::Error::ParseError
            nil
          end

          def binary_string?(string)
            string[0] == "\x00" || string[0] == "\x01" || string[0, 4] =~ /[0-9a-fA-F]{4}/
          end

          def wkt_parser(factory, string)
            if binary_string?(string)
              RGeo::WKRep::WKBParser.new(factory, support_ewkb: true, default_srid: @srid)
            else
              RGeo::WKRep::WKTParser.new(factory, support_ewkt: true, default_srid: @srid)
            end
          end

        end
      end
    end
  end
end
