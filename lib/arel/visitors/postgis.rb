module Arel  # :nodoc:
  module Visitors  # :nodoc:
    class PostGIS < PostgreSQL # :nodoc:

      FUNC_MAP = {
          'st_wkttosql' => 'ST_GeomFromEWKT',
      }

      def st_func(standard_name)
        FUNC_MAP[standard_name.downcase] || standard_name
      end

      def visit_String(node, collector)
        collector << "#{st_func('ST_WKTToSQL')}(#{quote(node)})"
      end

      def visit_RGeo_ActiveRecord_SpatialNamedFunction(node, collector)
        aggregate(st_func(node.name), node, collector)
      end

      def visit(node, *args)
        case node
          when RGeo::Feature::Instance
            visit_RGeo_Feature_Instance(node, *args)
          when RGeo::Cartesian::BoundingBox
            visit_RGeo_Cartesian_BoundingBox(node, *args)
          else
            super
        end
      end

    end

    VISITORS['postgis'] = PostGIS
  end
end
