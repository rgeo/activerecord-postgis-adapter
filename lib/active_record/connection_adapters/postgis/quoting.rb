# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module Quoting
        def type_cast(value)
          if RGeo::Feature::Geometry.check_type(value)
            RGeo::WKRep::WKBGenerator.new(hex_format: true, type_format: :ewkb, emit_ewkb_srid: true).generate(value)
          elsif value.is_a?(RGeo::Cartesian::BoundingBox)
            value.to_s
          else
            super
          end
        end

        # NOTE: This method should be private in future rails versions.
        #   Hence we should also make it private then.
        #
        # See https://github.com/rails/rails/blob/v8.1.1/activerecord/lib/active_record/connection_adapters/postgresql/quoting.rb#L190
        def lookup_cast_type(sql_type)
          type_map.lookup(
            # oid
            query_value("SELECT #{quote(sql_type)}::regtype::oid", "SCHEMA").to_i,
            # fmod, not needed.
            nil,
            # details needed for `..::PostGIS::OID::Spatial` (e.g. `geometry(point,3857)`)
            sql_type
          )
        end
      end
    end
  end
end
