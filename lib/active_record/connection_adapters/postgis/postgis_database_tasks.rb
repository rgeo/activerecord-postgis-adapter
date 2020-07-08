# frozen_string_literal: true

module ActiveRecord  # :nodoc:
  module ConnectionAdapters  # :nodoc:
    module PostGIS  # :nodoc:
      class PostGISDatabaseTasks < ::ActiveRecord::Tasks::PostgreSQLDatabaseTasks  # :nodoc:
        def initialize(config)
          super
          ensure_installation_configs
        end

        def setup_gis
          establish_su_connection
          if extension_names
            setup_gis_from_extension
          end
          establish_connection(configuration_hash)
        end

        # Override to set the database owner and call setup_gis
        def create(master_established = false)
          establish_master_connection unless master_established
          extra_configs = { encoding: encoding }
          extra_configs[:owner] = username if has_su?
          connection.create_database(configuration_hash[:database], configuration_hash.merge(extra_configs))
          setup_gis
        rescue ::ActiveRecord::StatementInvalid => error
          if /database .* already exists/ === error.message
            raise ::ActiveRecord::DatabaseAlreadyExists
          else
            raise
          end
        end

        private

        # Override to use su_username and su_password
        def establish_master_connection
          establish_connection(configuration_hash.merge(
            database:           "postgres",
            password:           su_password,
            schema_search_path: "public",
            username:           su_username
          ))
        end

        def establish_su_connection
          establish_connection(configuration_hash.merge(
            password:           su_password,
            schema_search_path: "public",
            username:           su_username
          ))
        end

        def username
          @username ||= configuration_hash[:username]
        end

        def quoted_username
          @quoted_username ||= ::ActiveRecord::Base.connection.quote_column_name(username)
        end

        def password
          @password ||= configuration_hash[:password]
        end

        def su_username
          @su_username ||= configuration_hash[:su_username] || username
        end

        def su_password
          @su_password ||= configuration_hash[:su_password] || password
        end

        def has_su?
          @has_su = configuration_hash.include?(:su_username) unless defined?(@has_su)
          @has_su
        end

        def search_path
          @search_path ||= configuration_hash[:schema_search_path].to_s.strip.split(",").map(&:strip)
        end

        def extension_names
          @extension_names ||= begin
            extensions = configuration_hash[:postgis_extension]
            case extensions
            when ::String
              extensions.split(",")
            when ::Array
              extensions
            else
              ["postgis"]
            end
          end
        end

        def ensure_installation_configs
          if configuration_hash[:setup] == "default" && !configuration_hash[:postgis_extension]
            share_dir = `pg_config --sharedir`.strip rescue "/usr/share"
            control_file = ::File.expand_path("extension/postgis.control", share_dir)
            if ::File.readable?(control_file)
              configuration_hash[:postgis_extension] = "postgis"
            end
          end
        end

        def setup_gis_from_extension
          extension_names.each do |extname|
            if extname == "postgis_topology"
              unless search_path.include?("topology")
                raise ArgumentError, "'topology' must be in schema_search_path for postgis_topology"
              end
              connection.execute("CREATE EXTENSION IF NOT EXISTS #{extname} SCHEMA topology")
            else
              if (postgis_schema = configuration_hash[:postgis_schema])
                schema_clause = "WITH SCHEMA #{postgis_schema}"
                unless schema_exists?(postgis_schema)
                  connection.execute("CREATE SCHEMA #{postgis_schema}")
                  connection.execute("GRANT ALL ON SCHEMA #{postgis_schema} TO PUBLIC")
                end
              else
                schema_clause = ""
              end

              connection.execute("CREATE EXTENSION IF NOT EXISTS #{extname} #{schema_clause}")
            end
          end
        end

        def schema_exists?(schema_name)
          connection.execute(
            "SELECT schema_name FROM information_schema.schemata WHERE schema_name = '#{schema_name}'"
          ).any?
        end
      end

      ::ActiveRecord::Tasks::DatabaseTasks.register_task(/postgis/, PostGISDatabaseTasks)
    end
  end
end

