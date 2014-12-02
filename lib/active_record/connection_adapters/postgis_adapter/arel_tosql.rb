module Arel  # :nodoc:
  module Visitors  # :nodoc:
    # Different super-class under JRuby JDBC adapter.
    PostGISSuperclass = if defined?(::ArJdbc::PostgreSQL::BindSubstitution)
                          ::ArJdbc::PostgreSQL::BindSubstitution
                        else
                          ::Arel::Visitors::PostgreSQL
                        end

    class PostGIS < PostGISSuperclass  # :nodoc:

      FUNC_MAP = {
        'st_wkttosql' => 'ST_GeomFromEWKT',
      }

      include ::RGeo::ActiveRecord::SpatialToSql

      def st_func(standard_name)
        FUNC_MAP[standard_name.downcase] || standard_name
      end

      alias_method :visit_in_spatial_context, :visit

    end

  end
end
