module ActiveRecord # :nodoc:
  module ConnectionAdapters # :nodoc:
    class PostGISColumn < PostgreSQLColumn # :nodoc:

      attr_reader :geographic, :srid, :spatial_type, :has_z, :has_m
      alias_method :geographic?, :geographic
      alias_method :has_z?, :has_z
      alias_method :has_m?, :has_m

      def initialize(factory_settings, table_name, name, default, oid_type, sql_type, null = true, opts = nil)
        @factory_settings = factory_settings
        @table_name = table_name
        @geographic = !!(sql_type =~ /geography/i)
        if opts
          # This case comes from an entry in the geometry_columns table
          @spatial_type = RGeo::ActiveRecord.geometric_type_from_name(opts[:type]) || RGeo::Feature::Geometry
          @limit = @srid = opts[:srid].to_i
          @has_z = opts[:has_z]
          @has_m = opts[:has_m]
        elsif @geographic
          # Geographic type information is embedded in the SQL type
          @spatial_type = RGeo::Feature::Geometry
          @srid = 4326
          @has_z = @has_m = false
          if sql_type =~ /geography\((.*)\)$/i
            params = $1.split(',')
            if params.size >= 2
              if params.first =~ /([a-z]+[^zm])(z?)(m?)/i
                @has_z = $2.length > 0
                @has_m = $3.length > 0
                @spatial_type = RGeo::ActiveRecord.geometric_type_from_name($1)
              end
              if params.last =~ /(\d+)/
                @srid = $1.to_i
              end
            end
          end
        end
        super(name, default, oid_type, sql_type, null)
        @type = @spatial_type.type_name.underscore
        @precision = true if @geographic
      end
    end
  end
end
