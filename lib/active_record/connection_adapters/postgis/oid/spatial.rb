module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module OID
        class Spatial # :nodoc:
          attr_reader :srid, :has_z, :has_m, :factory, :scale
          alias_method :has_z?, :has_z
          alias_method :has_m?, :has_m
          alias_method :limit, :srid

          def initialize(sql_type)
            @type = ['st']
            @srid = sql_type.split(',')[1].to_i
            @has_z = (sql_type =~ /z[,|)|m]/i).present?
            @has_m = (sql_type =~ /m[,|)]/i).present?

            set_type(sql_type)
            @type << 'z' if has_z
            @type << 'm' if has_m
          end

          def type
            @type.join('_').to_sym
          end

          #True for geography
          def precision
            false
          end

          alias_method :geographic?, :precision

          def type_cast_from_database(value)
            return if value.nil?
            RGeo::WKRep::WKBParser.new(@factory, support_ewkb: true).parse(value) rescue nil
          end

          def type_cast_for_database(value)
            if RGeo::Feature::Geometry.check_type(value)
              RGeo::WKRep::WKBGenerator.new(hex_format: true, type_format: :ewkb, emit_ewkb_srid: true).generate(value)
            elsif value.is_a?(RGeo::Cartesian::BoundingBox)
              "'#{value.min_x},#{value.min_y},#{value.max_x},#{value.max_y}'::box"
            end
          end

          # Determines whether a value has changed for dirty checking. +old_value+
          # and +new_value+ will always be type-cast. Types should not need to
          # override this method.
          def changed?(old_value, new_value, _new_value_before_type_cast)
            old_value != new_value
          end

          def binary?
            false
          end

          def type_cast_from_user(value)
            type_cast_from_database(type_cast_for_database(type_cast_from_string(value)))
          end

          # +raw_old_value+ will be the `_before_type_cast` version of the
          # value (likely a string). +new_value+ will be the current, type
          # cast value.
          def changed_in_place?(raw_old_value, new_value)
            type_cast_from_database(raw_old_value) != new_value
          end

          private
            def set_type(sql_type)
              if sql_type =~ /\((\w+)[,|)]/
                sql_type = $1.gsub(/zm$|z$|m$/i, '')
                st_type = sql_type.underscore.gsub(/zm$/i, 'z_m')
              else
                st_type = default_type
              end
              @type.insert(1, st_type)
            end

            def type_cast_from_string(value)
              return value unless value.is_a?(String)
              begin
                RGeo::WKRep::WKTParser.new(@factory, support_ewkt: true).parse(value)
              rescue RGeo::Error::ParseError
                begin
                  RGeo::WKRep::WKBParser.new(@factory, support_ewkb: true).parse(value)
                rescue
                  nil
                end
              end
            end
        end
      end
    end
  end
end
