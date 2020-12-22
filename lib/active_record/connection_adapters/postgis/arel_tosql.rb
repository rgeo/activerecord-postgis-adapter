# frozen_string_literal: true

module RGeo
  module ActiveRecord
    module SpatialToSqlExtension
      def visit_in_spatial_context(node, collector)
        if node.is_a?(String) && node =~ /^SRID=[\d+]{0,};/
          msg = "EWKT Strings are no longer recommended for Arel.spatial queries, please use the RGeo::WKRep::WKTParser class to convert this to an RGeo Feature first."
          ActiveSupport::Deprecation.warn(msg)
          parser = RGeo::WKRep::WKTParser.new(nil, support_ewkt: true)
          node = parser.parse(node)
        end
        super(node, collector)
      end
    end
  end
end
RGeo::ActiveRecord::SpatialToSql.prepend RGeo::ActiveRecord::SpatialToSqlExtension

module Arel  # :nodoc:
  module Visitors  # :nodoc:
    # Different super-class under JRuby JDBC adapter.
    PostGISSuperclass = if defined?(::ArJdbc::PostgreSQL::BindSubstitution)
                          ::ArJdbc::PostgreSQL::BindSubstitution
                        else
                          PostgreSQL
                        end

    class PostGIS < PostGISSuperclass  # :nodoc:
      include RGeo::ActiveRecord::SpatialToSql
    end
  end
end
