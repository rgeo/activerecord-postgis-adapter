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
      end
    end
  end
end
