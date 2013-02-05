# -----------------------------------------------------------------------------
#
# PostGIS adapter for ActiveRecord
#
# -----------------------------------------------------------------------------
# Copyright 2010-2012 Daniel Azuma
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# * Neither the name of the copyright holder, nor the names of any other
#   contributors to this software, may be used to endorse or promote products
#   derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# -----------------------------------------------------------------------------
;


# :stopdoc:

module ActiveRecord

  module ConnectionAdapters

    module PostGISAdapter

      class PostGISDatabaseTasks < ::ActiveRecord::Tasks::PostgreSQLDatabaseTasks


        def initialize(config_)
          super
          ensure_installation_configs
        end


        def setup_gis
          setup_gis_schemas
          if script_dir
            setup_gis_from_script_dir
          elsif extension_names
            setup_gis_from_extension
          end
          if has_su? && (script_dir || extension_names)
            setup_gis_grant_privileges
          end
        end


        # Overridden to set the database owner and call setup_gis

        def create(master_established_=false)
          establish_master_connection unless master_established_
          extra_configs_ = {'encoding' => encoding}
          extra_configs_['owner'] = username if has_su?
          connection.create_database(configuration['database'], configuration.merge(extra_configs_))
          establish_connection(configuration) unless master_established_
          setup_gis
        rescue ::ActiveRecord::StatementInvalid => error_
          if /database .* already exists/ === error_.message
            raise ::ActiveRecord::Tasks::DatabaseAlreadyExists
          else
            raise
          end
        end


        # Overridden to remove postgis schema

        def structure_dump(filename_)
          set_psql_env
          search_path_ = search_path.dup
          search_path_.delete('postgis')
          search_path_ = ['public'] if search_path_.length == 0
          search_path_clause_ = search_path_.map{ |part_| "--schema=#{::Shellwords.escape(part_)}" }.join(' ')
          command_ = "pg_dump -i -s -x -O -f #{::Shellwords.escape(filename_)} #{search_path_clause_} #{::Shellwords.escape(configuration['database'])}"
          raise 'Error dumping database' unless ::Kernel.system(command_)
          ::File.open(filename_, "a") { |f_| f_ << "SET search_path TO #{ActiveRecord::Base.connection.schema_search_path};\n\n" }
        end


        private


        # Overridden to use su_username and su_password

        def establish_master_connection
          establish_connection(configuration.merge(
            'database' => 'postgres',
            'schema_search_path' => 'public',
            'username' => su_username,
            'password' => su_password))
        end


        def username
          @username ||= configuration['username']
        end

        def quoted_username
          @quoted_username ||= ::PGconn.quote_ident(username)
        end

        def password
          @password ||= configuration['password']
        end

        def su_username
          @su_username ||= configuration['su_username'] || username
        end

        def su_password
          @su_password ||= configuration['su_password'] || password
        end

        def has_su?
          @has_su = configuration.include?('su_username') unless defined?(@has_su)
          @has_su
        end

        def search_path
          @search_path ||= configuration['schema_search_path'].to_s.strip.split(',').map(&:strip)
        end

        def postgis_schema
          @postgis_schema ||= search_path.include?('postgis') ? 'postgis' : (search_path.last || 'public')
        end

        def script_dir
          @script_dir = configuration['script_dir'] unless defined?(@script_dir)
          @script_dir
        end

        def extension_names
          @extension_names ||= begin
            ext_ = configuration['postgis_extension']
            case ext_
            when ::String
              ext_.split(',')
            when ::Array
              ext_
            else
              ['postgis']
            end
          end
        end


        def ensure_installation_configs
          if !configuration['script_dir'] && !configuration['postgis_extension']
            establish_master_connection
            postgres_version_ = connection.select_value('SELECT VERSION()').to_s
            if postgres_version_ =~ /(\d+)\.(\d+)(\.\d+)?/
              postgres_version_major_ = $1.to_i
              postgres_version_minor_ = $2.to_i
            else
              postgres_version_major_ = postgres_version_minor_ = 0
            end
            postgis_version_ = connection.select_value('SELECT POSTGIS_VERSION()').to_s
            if postgis_version_ =~ /(\d+)\.(\d+)(\.\d+)?/
              postgis_version_major_ = $1.to_i
            else
              postgis_version_major_ = 0
            end
            if postgis_version_major_ >= 2 && (postgres_version_major_ > 9 || postgres_version_major_ == 9 && postgres_version_minor_ >= 2)
              configuration['postgis_extension'] = 'postgis'
            else
              sharedir_ = `pg_config --sharedir`.strip rescue '/usr/share'
              configuration['script_dir'] = ::File.expand_path('contrib/postgis-1.5', sharedir_)
            end
          end
        end


        def setup_gis_schemas
          establish_connection(configuration.merge('schema_search_path' => 'public'))
          auth_ = has_su? ? " AUTHORIZATION #{quoted_username}" : ''
          search_path.each do |schema_|
            if schema_.downcase != 'public' && !connection.execute("SELECT 1 FROM pg_catalog.pg_namespace WHERE nspname='#{schema_}'").try(:first)
              connection.execute("CREATE SCHEMA #{schema_}#{auth_}")
            end
          end
          establish_connection(configuration)
        end


        def setup_gis_from_extension
          extension_names.each do |extname_|
            if extname_ == 'postgis_topology'
              raise ::ArgumentError, "'topology' must be in schema_search_path for postgis_topology" unless search_path.include?('topology')
              connection.execute("CREATE EXTENSION #{extname_} SCHEMA topology")
            else
              connection.execute("CREATE EXTENSION #{extname_} SCHEMA #{postgis_schema}")
            end
          end
        end


        def setup_gis_from_script_dir
          connection.execute("SET search_path TO #{postgis_schema}")
          connection.execute(::File.read(::File.expand_path('postgis.sql', script_dir)))
          connection.execute(::File.read(::File.expand_path('spatial_ref_sys.sql', script_dir)))
        end


        def setup_gis_grant_privileges
          connection.execute("GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA #{postgis_schema} TO #{quoted_username}")
          connection.execute("GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA #{postgis_schema} TO #{quoted_username}")
          postgis_version_ = connection.execute( "SELECT #{postgis_schema}.postgis_version();" ).first['postgis_version']
          if postgis_version_ =~ /^2/
            connection.execute("ALTER VIEW #{postgis_schema}.geometry_columns OWNER TO #{quoted_username}")
          else
            connection.execute("ALTER TABLE #{postgis_schema}.geometry_columns OWNER TO #{quoted_username}")
          end
          connection.execute("ALTER TABLE #{postgis_schema}.spatial_ref_sys OWNER TO #{quoted_username}")
        end


      end


      ::ActiveRecord::Tasks::DatabaseTasks.register_task(/postgis/, PostGISDatabaseTasks)


    end

  end

end

# :startdoc:
