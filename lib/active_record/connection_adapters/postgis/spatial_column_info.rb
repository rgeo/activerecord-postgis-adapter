# frozen_string_literal: true

module ActiveRecord  # :nodoc:
  module ConnectionAdapters  # :nodoc:
    module PostGIS
      # Do spatial sql queries for column info and memoize that info.
      class SpatialColumnInfo
        def initialize(adapter, table_name)
          @adapter = adapter
          @table_name = table_name
        end

        # Query geometry_columns for several tables at once.
        # Returns { table_name => { column_name => info } }.
        def self.fetch(adapter, table_names)
          sql = "SELECT f_table_name,f_geometry_column,coord_dimension,srid,type FROM geometry_columns " \
                "WHERE f_table_name IN (#{table_names.map { |name| adapter.quote(name.to_s) }.join(',')})"
          # Rails 8.2 replaced `query` with `query_rows`
          rows = adapter.respond_to?(:query_rows) ? adapter.query_rows(sql) : adapter.query(sql)
          result = table_names.to_h { |name| [name.to_s, {}] }
          rows.each do |table_name, name, dimension, srid, type|
            next unless (columns = result[table_name])

            dimension = dimension.to_i
            has_m = !!(type =~ /m$/i)
            type = type.sub(/m$/, "")
            has_z = dimension > 3 || (dimension == 3 && !has_m)
            columns[name] = {
              dimension: dimension,
              has_m:     has_m,
              has_z:     has_z,
              name:      name,
              srid:      srid.to_i,
              type:      type,
            }
          end
          result
        end

        def all
          self.class.fetch(@adapter, [@table_name]).fetch(@table_name)
        end

        def loaded?
          !@spatial_column_info.nil?
        end

        def load(info)
          @spatial_column_info = info
        end

        # do not query the database for non-spatial columns/tables
        def get(column_name, type)
          return unless PostGISAdapter.spatial_column_options(type.to_sym)
          @spatial_column_info ||= all
          @spatial_column_info[column_name]
        end
      end
    end
  end
end
