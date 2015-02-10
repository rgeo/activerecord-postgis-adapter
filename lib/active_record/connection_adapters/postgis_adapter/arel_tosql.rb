module Arel  # :nodoc:
  module Visitors  # :nodoc:
    # Different super-class under JRuby JDBC adapter.
    PostGISSuperclass = if defined?(::ArJdbc::PostgreSQL::BindSubstitution)
                          ::ArJdbc::PostgreSQL::BindSubstitution
                        else
                          PostgreSQL
                        end

    class PostGIS < PostGISSuperclass  # :nodoc:

      FUNC_MAP = {
        'st_wkttosql' => 'ST_GeomFromEWKT',
      }

      include RGeo::ActiveRecord::SpatialToSql

      def st_func(standard_name)
        FUNC_MAP[standard_name.downcase] || standard_name
      end

      def visit_String(node, collector)
        collector << "#{st_func('ST_WKTToSQL')}(#{quote(node)})"
      end

      def visit_RGeo_ActiveRecord_SpatialNamedFunction(node, collector)
        aggregate(st_func(node.name), node, collector)
      end

    end

  end
end
