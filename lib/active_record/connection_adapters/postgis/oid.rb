require_relative 'oid/spatial'
require_relative 'oid/st_geography'
require_relative 'oid/st_geometry'

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module OID # :nodoc:
      end
    end
  end
end