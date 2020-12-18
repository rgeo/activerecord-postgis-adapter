# frozen_string_literal: true

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
