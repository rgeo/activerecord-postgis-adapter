module ActiveRecord  # :nodoc:
  module ConnectionAdapters  # :nodoc:
    module PostGISAdapter  # :nodoc:
      class SpatialColumn < ConnectionAdapters::PostgreSQLColumn  # :nodoc:

        # sql_type examples:
        #   "Geometry(Point, 4326)"
        #   "Geography(Point, 4326)"
        # cast_type example classes:
        #   OID::Spatial
        #   OID::Integer
        def initialize(factory_settings, table_name, name, default, cast_type, sql_type = nil, null = true, opts = nil)
          @factory_settings = factory_settings
          @table_name = table_name
          @geographic = !!(sql_type =~ /geography/i)
          if opts
            # This case comes from an entry in the geometry_columns table
            @geometric_type = RGeo::ActiveRecord.geometric_type_from_name(opts[:type]) || RGeo::Feature::Geometry
            @srid = opts[:srid].to_i
            @has_z = !!opts[:has_z]
            @has_m = !!opts[:has_m]
          elsif @geographic
            # Geographic type information is embedded in the SQL type
            @geometric_type = RGeo::Feature::Geometry
            @srid = 4326
            @has_z = @has_m = false
            if sql_type =~ /geography\((.*)\)$/i
              params = $1.split(',')
              if params.size >= 2
                if params.first =~ /([a-z]+[^zm])(z?)(m?)/i
                  @has_z = $2.length > 0
                  @has_m = $3.length > 0
                  @geometric_type = RGeo::ActiveRecord.geometric_type_from_name($1)
                end
                if params.last =~ /(\d+)/
                  @srid = $1.to_i
                end
              end
            end
          elsif sql_type =~ /geography|geometry|point|linestring|polygon/i
            # A geometry column with no geometry_columns entry.
            @geometric_type = RGeo::ActiveRecord.geometric_type_from_name(sql_type)
          end
          super(name, default, cast_type, sql_type, null)
          if spatial?
            if @srid
              @limit = { srid: @srid, type: @geometric_type.type_name.underscore }
              @limit[:has_z] = true if @has_z
              @limit[:has_m] = true if @has_m
              @limit[:geographic] = true if @geographic
            end
          end
        end

        attr_reader :geographic
        attr_reader :srid
        attr_reader :geometric_type
        attr_reader :has_z
        attr_reader :has_m

        alias_method :geographic?, :geographic
        alias_method :has_z?, :has_z
        alias_method :has_m?, :has_m

        def spatial?
          cast_type.respond_to?(:spatial?) && cast_type.spatial?
        end

        def has_spatial_constraints?
          !@srid.nil?
        end
      end

      module OID
        # Register spatial types so we can recognize custom columns coming from the database.
        class Spatial < Type::Value  # :nodoc:

          def initialize(options = {})
            @factory_generator = options[:factory_generator]
          end

          def geographic?
            !!@factory_generator
          end

          def type
            geographic? ? :geography : :geometry
          end

          def klass
            geographic? ? RGeo::Feature::Geography : RGeo::Feature::Geometry
          end

          def spatial?
            true
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

          def type_cast_from_database(value)
            cast_value value
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
          rescue # delete me
            byebug
          end

          # convert WKT string into RGeo object
          def parse_wkt(string)
            # factory = factory_settings.get_column_factory(table_name, column, constraints)
            factory = RGeo::ActiveRecord::RGeoFactorySettings.new
            wkt_parser(factory, string).parse(string)
          rescue RGeo::Error::ParseError
            nil
          rescue # delete me
            byebug
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
