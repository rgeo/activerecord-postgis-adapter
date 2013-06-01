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


require 'rgeo/active_record/task_hacker'


class Object
  alias_method :create_database_without_postgis, :create_database
  alias_method :drop_database_without_postgis, :drop_database
end


namespace :db do
  namespace :gis do
    desc "Setup PostGIS data in the database"
    task :setup => [:load_config, :rails_env] do
      if self.respond_to?(:configs_for_environment)
        configs_ = configs_for_environment
      else
        environments_ = [::Rails.env]
        environments_ << 'test' if ::Rails.env.development?
        configs_ = ::ActiveRecord::Base.configurations.values_at(*environments_).compact.reject{ |config_| config_['database'].blank? }
      end
      configs_.each { |config_| setup_gis(config_) }
    end
  end
end


# superuser name/password
def get_su_auth(config_)
  username_ = config_['username']
  su_username_ = config_['su_username'] || username_
  su_password_ = config_['su_password'] || config_['password']
  has_su_ = config_.include?('su_username')

  [username_, su_username_, su_password_, has_su_]
end


def get_search_path(config_)
  config_["schema_search_path"].to_s.strip.split(',').map(&:strip)
end


# Install postgis definitions into the database.
# Note: a superuser is required to run the postgis definitions.
# If a separate superuser is provided, we need to grant privileges on
# the postgis definitions over to the regular user afterwards.
# We also need to set the ownership of the postgis tables (spatial_ref_sys
# and geometry_columns) to the regular user. This is required to e.g.
# be able to disable referential integrity on the database when using
# a database cleaner truncation strategy during testing.
# The schema for the postgis definitions is chosen as follows:
# If "postgis" is present in the search path, use it.
# Otherwise, use the last schema in the search path.
# If no search path is given, use "public".
def setup_gis(config_)
  # Initial setup of the database: Add schemas from the search path.
  # If a superuser is given, we log in as the superuser, but we make sure
  # the schemas are owned by the regular user.
  username_, su_username_, su_password_, has_su_ = get_su_auth(config_)
  ::ActiveRecord::Base.establish_connection(config_.merge('schema_search_path' => 'public', 'username' => su_username_, 'password' => su_password_))
  conn_ = ::ActiveRecord::Base.connection
  search_path_ = get_search_path(config_)
  quoted_username_ = ::ActiveRecord::Base.connection.quote_column_name(username_)
  auth_ = has_su_ ? " AUTHORIZATION #{quoted_username_}" : ''
  search_path_.each do |schema_|
    exists = schema_.downcase == 'public' || conn_.execute("SELECT 1 FROM pg_catalog.pg_namespace WHERE nspname='#{schema_}'").try(:first)
    conn_.execute("CREATE SCHEMA #{schema_}#{auth_}") unless exists
  end

  script_dir_ = config_['script_dir']
  postgis_extension_ = config_['postgis_extension']
  if script_dir_ || postgis_extension_
    postgis_schema_ = search_path_.include?('postgis') ? 'postgis' : (search_path_.last || 'public')
    if script_dir_
      # Use script_dir (for postgresql < 9.1 or postgis < 2.0)
      conn_.execute("SET search_path TO #{postgis_schema_}")
      conn_.execute(::File.read(::File.expand_path('postgis.sql', script_dir_)))
      conn_.execute(::File.read(::File.expand_path('spatial_ref_sys.sql', script_dir_)))
    elsif postgis_extension_
      # Use postgis_extension (for postgresql >= 9.1 and postgis >= 2.0)
      postgis_extension_ = 'postgis' if postgis_extension_ == true
      postgis_extension_ = postgis_extension_.to_s.split(',') unless postgis_extension_.is_a?(::Array)
      postgis_extension_.each do |extname_|
        if extname_ == 'postgis_topology'
          raise ArgumentError, "'topology' must be in schema_search_path for postgis_topology" unless search_path_.include?('topology')
          conn_.execute("CREATE EXTENSION #{extname_} SCHEMA topology")
        else
          conn_.execute("CREATE EXTENSION #{extname_} SCHEMA #{postgis_schema_}")
        end
      end
    end
    if has_su_
      conn_.execute("GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA #{postgis_schema_} TO #{quoted_username_}")
      conn_.execute("GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA #{postgis_schema_} TO #{quoted_username_}")

      postgis_version = conn_.execute( "SELECT #{postgis_schema_}.postgis_version();" ).first[ 'postgis_version' ]
      if postgis_version =~ /^2/
        conn_.execute("ALTER VIEW #{postgis_schema_}.geometry_columns OWNER TO #{quoted_username_}")
        conn_.execute("ALTER VIEW #{postgis_schema_}.geography_columns OWNER TO #{quoted_username_}")
      else
        conn_.execute("ALTER TABLE #{postgis_schema_}.geometry_columns OWNER TO #{quoted_username_}")
      end
      conn_.execute("ALTER TABLE #{postgis_schema_}.spatial_ref_sys OWNER TO #{quoted_username_}")
    end
  end
end


def create_database(config_)
  if config_['adapter'] == 'postgis'
    @encoding = config_['encoding'] || ::ENV['CHARSET'] || 'utf8'
    begin
      username_, su_username_, su_password_, has_su_ = get_su_auth(config_)

      # Create the database. Optionally do so as the given superuser.
      # But make sure the database is owned by the regular user.
      ::ActiveRecord::Base.establish_connection(config_.merge('database' => 'postgres', 'schema_search_path' => 'public', 'username' => su_username_, 'password' => su_password_))
      extra_configs_ = {'encoding' => @encoding}
      extra_configs_['owner'] = username_ if has_su_
      ::ActiveRecord::Base.connection.create_database(config_['database'], config_.merge(extra_configs_))

      setup_gis(config_)

      # Done
      ::ActiveRecord::Base.establish_connection(config_)
    rescue ::Exception => e_
      $stderr.puts(e_, *(e_.backtrace))
      $stderr.puts("Couldn't create database for #{config_.inspect}")
    end
  else
    create_database_without_postgis(config_)
  end
end


def drop_database(config_)
  if config_['adapter'] == 'postgis'
    ::ActiveRecord::Base.establish_connection(config_.merge('database' => 'postgres', 'schema_search_path' => 'public', 'username' => config_['su_username'] || config_['username'], 'password' => config_['su_password'] || config_['password']))
    ::ActiveRecord::Base.connection.drop_database(config_['database'])
  else
    drop_database_without_postgis(config_)
  end
end


def set_psql_env(config_)
  ::ENV['PGHOST'] = config_["host"] if config_["host"]
  ::ENV['PGPORT'] = config_["port"].to_s if config_["port"]
  ::ENV['PGPASSWORD'] = config_["password"].to_s if config_["password"]
  ::ENV['PGUSER'] = config_["username"].to_s if config_["username"]
end


::RGeo::ActiveRecord::TaskHacker.modify('db:charset', nil, 'postgis') do |config_|
  ::ActiveRecord::Base.establish_connection(config_)
  puts(::ActiveRecord::Base.connection.encoding)
end


::RGeo::ActiveRecord::TaskHacker.modify('db:structure:dump', nil, 'postgis') do |config_|
  set_psql_env(config_)
  filename_ = ::File.join(::Rails.root, "db/#{::Rails.env}_structure.sql")
  search_path_ = config_["schema_search_path"].to_s.strip
  search_path_ = search_path_.split(",").map{ |sp_| sp_.strip }
  search_path_.delete('postgis')
  search_path_ = ['public'] if search_path_.length == 0
  search_path_ = search_path_.map{ |sp_| "--schema=#{sp_}" }.join(" ")
  `pg_dump -i -U "#{config_["username"]}" -s -x -O -f #{filename_} #{search_path_} #{config_["database"]}`
  raise "Error dumping database" if $?.exitstatus == 1
end


::RGeo::ActiveRecord::TaskHacker.modify('db:structure:load', nil, 'postgis') do |config_|
  set_psql_env(config_)
  filename_ = ::File.join(::Rails.root, "db/#{::Rails.env}_structure.sql")
  `psql -f #{filename_} #{config_["database"]}`
end


::RGeo::ActiveRecord::TaskHacker.modify('db:test:clone_structure', 'test', 'postgis') do |config_|
  set_psql_env(config_)
  `psql -U "#{config_["username"]}" -f #{::Rails.root}/db/#{::Rails.env}_structure.sql #{config_["database"]}`
end


::RGeo::ActiveRecord::TaskHacker.modify('db:test:purge', 'test', 'postgis') do |config_|
  ::ActiveRecord::Base.clear_active_connections!
  drop_database(config_)
  create_database(config_)
end


# :startdoc:
