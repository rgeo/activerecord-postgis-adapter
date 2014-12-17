module ActiveRecord  # :nodoc:
  module ConnectionAdapters  # :nodoc:
    module PostGISAdapter  # :nodoc:
      class SpatialColumn < ConnectionAdapters::PostgreSQLColumn  # :nodoc:

        def initialize(factory_settings, table_name, name, default, cast_type, sql_type = nil, null = true, opts = nil)
          @factory_settings = factory_settings
          @table_name = table_name
          @geographic = !!(sql_type =~ /geography/i)
          if opts
            # This case comes from an entry in the geometry_columns table
            @geometric_type = RGeo::ActiveRecord.geometric_type_from_name(opts[:type]) || ::RGeo::Feature::Geometry
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

        def type_cast(value)
          if spatial?
            SpatialColumn.convert_to_geometry(value, @factory_settings, @table_name, name,
              @geographic, @srid, @has_z, @has_m)
          else
            super
          end
        end

        private

        def simplified_type(sql_type)
          sql_type =~ /geography|geometry|point|linestring|polygon/i ? :spatial : super
        end

        def self.convert_to_geometry(input, factory_settings, table_name, column, geographic, srid, has_z, has_m)
          if srid
            constraints = {
              geographic:       geographic,
              has_z_coordinate: has_z,
              has_m_coordinate: has_m,
              srid:             srid
            }
          else
            constraints = nil
          end
          if RGeo::Feature::Geometry === input
            factory = factory_settings.get_column_factory(table_name, column, constraints)
            RGeo::Feature.cast(input, factory) rescue nil
          elsif input.respond_to?(:to_str)
            input = input.to_str
            if input.length == 0
              nil
            else
              factory = factory_settings.get_column_factory(table_name, column, constraints)
              marker = input[0]
              if marker == "\x00" || marker == "\x01" || input[0,4] =~ /[0-9a-fA-F]{4}/
                RGeo::WKRep::WKBParser.new(factory, support_ewkb: true).parse(input) rescue nil
              else
                RGeo::WKRep::WKTParser.new(factory, support_ewkt: true).parse(input) rescue nil
              end
            end
          else
            nil
          end
        end

      end

      module OID
        # Register spatial types so we can recognize custom columns coming from the database.
        class Spatial < Type::Value  # :nodoc:

          def initialize(options = {})
            @factory_generator = options[:factory_generator]
          end

          def type
            :spatial
          end

          def klass
            RGeo::Feature::Geometry
          end

          def spatial?
            true
          end

          def type_cast(value)
            if ::RGeo::Feature::Geometry.check_type(value)
              ::RGeo::WKRep::WKBGenerator.new(hex_format: true, type_format: :ewkb, emit_ewkb_srid: true).generate(value)
            else
              super
            end
          end

          private

          def cast_value(value)
            ::RGeo::WKRep::WKBParser.new(@factory_generator, support_ewkb: true).parse(value) rescue nil
          end

        end
      end

      # This is a hack to ActiveRecord::ModelSchema. We have to "decorate" the decorate_columns
      # method to apply class-specific customizations to spatial type casting.
      module DecorateColumnsModification  # :nodoc:

        def decorate_columns(columns_hash)
          columns_hash = super(columns_hash)
          return unless columns_hash
          canonical_columns_ = self.columns_hash
          columns_hash.each do |name, col|
            if col.is_a?(SpatialOID) && (canonical = canonical_columns_[name]) && canonical.spatial?
              columns_hash[name] = canonical
            end
          end
          columns_hash
        end

      end

      ::ActiveRecord::Base.extend(DecorateColumnsModification)

    end
  end
end
