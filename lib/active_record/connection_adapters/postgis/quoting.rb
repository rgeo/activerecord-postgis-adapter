# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module Quoting
        def type_cast(value)
          case value
          when RGeo::Feature::Instance
            RGeo::WKRep::WKBGenerator
              .new(hex_format: true, type_format: :ewkb, emit_ewkb_srid: true)
              .generate(value)
          else
            super
          end
        end
      end
    end
  end
end
