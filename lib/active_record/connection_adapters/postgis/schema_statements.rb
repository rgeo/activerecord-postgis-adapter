# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module SchemaStatements
        # override
        # https://github.com/rails/rails/blob/7-0-stable/activerecord/lib/active_record/connection_adapters/postgresql/schema_statements.rb#L662
        # Create a SpatialColumn instead of a PostgreSQL::Column
        def new_column_from_field(table_name, field, _definitions, slot = nil)
          column_name, type, default, notnull, oid, fmod, collation, comment, identity, attgenerated = field
          type_metadata = fetch_type_metadata(column_name, type, oid.to_i, fmod.to_i)
          default_value = extract_value_from_default(default)

          default_function = if attgenerated.present?
                               default
                             else
                               extract_default_function(default_value, default)
                             end

          if (match = default_function&.match(/\Anextval\('"?(?<sequence_name>.+_(?<suffix>seq\d*))"?'::regclass\)\z/))
            serial = sequence_name_from_parts(table_name, column_name, match[:suffix]) == match[:sequence_name]
          end

          # {:dimension=>2, :has_m=>false, :has_z=>false, :name=>"latlon", :srid=>0, :type=>"GEOMETRY"}
          spatial = spatial_column_info(table_name).get(column_name, type_metadata.sql_type)

          Column.new(
            column_name,
            get_oid_type(oid.to_i, fmod.to_i, column_name, type),
            default_value,
            type_metadata,
            !notnull,
            default_function,
            collation: collation,
            comment: comment.presence,
            serial: serial,
            generated: attgenerated,
            identity: identity.presence,
            spatial: spatial,
            slot: slot
          )
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

        # Returns an array of view names defined in the database.
        def views
          super - %w[geography_columns geometry_columns]
        end

        private

        # Rails 8.2 reads the columns of many tables in one query, so look up
        # what else they need in one query each too, rather than one per table:
        # the extension types (geometry, geography), which Rails loads on first
        # use, and the geometry_columns info
        def fetch_column_definitions(tables)
          definitions = super
          load_additional_types(definitions.values.flatten(1).map { |field| field[4] })
          unloaded = definitions.filter_map do |table_name, fields|
            next if spatial_column_info(table_name).loaded?

            table_name if fields.any? { |field| PostGISAdapter.spatial_column_options(field[1].to_sym) }
          end
          unless unloaded.empty?
            SpatialColumnInfo.fetch(self, unloaded).each do |table_name, info|
              spatial_column_info(table_name).load(info)
            end
          end
          definitions
        end
      end
    end
  end
end
