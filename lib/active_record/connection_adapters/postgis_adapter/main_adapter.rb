module ActiveRecord  # :nodoc:
  module ConnectionAdapters  # :nodoc:
    module PostGISAdapter  # :nodoc:
      class MainAdapter < PostgreSQLAdapter  # :nodoc:
        def initialize(*args)
          # Change the visitor
          super
          @visitor = ::Arel::Visitors::PostGIS.new(self)
        end

        include PostGISAdapter::CommonAdapterMethods
        include PostGISAdapter::SchemaStatements

        def schema_creation
          PostGISAdapter::SchemaCreation.new self
        end

        def native_database_types
          # Add spatial types
          super.merge(
            geography: { name: 'geography' },
            spatial:   { name: 'geometry' },
          )
        end

        # override
        def create_table_definition(name, temporary, options, as = nil)
          PostGISAdapter::TableDefinition.new(native_database_types, name, temporary, options, as, self)
        end

      end
    end
  end
end
