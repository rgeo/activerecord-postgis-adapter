# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module SchemaStatements
        # override
        # https://github.com/rails/rails/blob/7-0-stable/activerecord/lib/active_record/connection_adapters/postgresql/schema_statements.rb#L662
        # Create a SpatialColumn instead of a PostgreSQL::Column
        def new_column_from_field(table_name, field)
          column_name, type, default, notnull, oid, fmod, collation, comment, attgenerated = field
          type_metadata = fetch_type_metadata(column_name, type, oid.to_i, fmod.to_i)
          default_value = extract_value_from_default(default)
          default_function = extract_default_function(default_value, default)

          if match = default_function&.match(/\Anextval\('"?(?<sequence_name>.+_(?<suffix>seq\d*))"?'::regclass\)\z/)
            serial = sequence_name_from_parts(table_name, column_name, match[:suffix]) == match[:sequence_name]
          end

          # {:dimension=>2, :has_m=>false, :has_z=>false, :name=>"latlon", :srid=>0, :type=>"GEOMETRY"}
          spatial = spatial_column_info(table_name).get(column_name, type_metadata.sql_type)

          SpatialColumn.new(
            column_name,
            default_value,
            type_metadata,
            !notnull,
            default_function,
            collation: collation,
            comment: comment.presence,
            serial: serial,
            generated: attgenerated,
            spatial: spatial
          )
        end

        # override
        # https://github.com/rails/rails/blob/7-0-stable/activerecord/lib/active_record/connection_adapters/postgresql/schema_statements.rb#L547
        #
        # returns Postgresql sql type string
        # examples:
        #   "geometry(Point,4326)"
        #   "geography(Point,4326)"
        #
        # note: type alone is not enough to detect the sql type,
        # so `limit` is used to pass the additional information. :(
        #
        # type_to_sql(:geography, limit: "Point,4326")
        # => "geography(Point,4326)"
        def type_to_sql(type, limit: nil, precision: nil, scale: nil, array: nil, **)
          sql = \
            case type.to_s
            when "geometry", "geography"
              "#{type}(#{limit})"
            when "binary"
              # PostgreSQL doesn't support limits on binary (bytea) columns.
              # The hard limit is 1GB, because of a 32-bit size field, and TOAST.
              case limit
              when nil, 0..0x3fffffff; super(type)
              else raise ArgumentError, "No binary type has byte size #{limit}. The limit on binary can be at most 1GB - 1byte."
              end
            when "text"
              # PostgreSQL doesn't support limits on text columns.
              # The hard limit is 1GB, according to section 8.3 in the manual.
              case limit
              when nil, 0..0x3fffffff; super(type)
              else raise ArgumentError, "No text type has byte size #{limit}. The limit on text can be at most 1GB - 1byte."
              end
            when "integer"
              case limit
              when 1, 2; "smallint"
              when nil, 3, 4; "integer"
              when 5..8; "bigint"
              else raise ArgumentError, "No integer type has byte size #{limit}. Use a numeric with scale 0 instead."
              end
            when "enum"
              raise ArgumentError, "enum_type is required for enums" if enum_type.nil?

              enum_type
            else
              super
            end

          sql = "#{sql}[]" if array && type != :primary_key
          sql
        end

        # override
        def create_table_definition(*args, **kwargs)
          PostGIS::TableDefinition.new(self, *args, **kwargs)
        end

        # memoize hash of column infos for tables
        def spatial_column_info(table_name)
          @spatial_column_info ||= {}
          @spatial_column_info[table_name.to_sym] ||= SpatialColumnInfo.new(self, table_name.to_s)
        end
      end
    end
  end
end
