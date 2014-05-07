module Arel  # :nodoc:
  module Visitors  # :nodoc:

    class PostGIS < PostgreSQL  # :nodoc:

      FUNC_MAP = {
        'st_wkttosql' => 'ST_GeomFromEWKT',
      }

      include ::RGeo::ActiveRecord::SpatialToSql

      def st_func(standard_name_)
        FUNC_MAP[standard_name_.downcase] || standard_name_
      end

      alias_method :visit_in_spatial_context, :visit

    end

    VISITORS['postgis'] = ::Arel::Visitors::PostGIS

  end
end
