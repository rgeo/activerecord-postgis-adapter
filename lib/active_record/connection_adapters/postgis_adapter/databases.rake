# -----------------------------------------------------------------------------
# 
# Rakefile changes for PostGIS adapter
# 
# -----------------------------------------------------------------------------
# Copyright 2010 Daniel Azuma
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


require 'rgeo/active_record/task_hacker'


class Object
  alias_method :create_database_without_postgis, :create_database
  alias_method :drop_database_without_postgis, :drop_database
end


def create_database(config_)
  if config_['adapter'] == 'postgis'
    @encoding = config_['encoding'] || ::ENV['CHARSET'] || 'utf8'
    begin
      ::ActiveRecord::Base.establish_connection(config_.merge('database' => 'postgres', 'schema_search_path' => 'public'))
      ::ActiveRecord::Base.connection.create_database(config_['database'], config_.merge('encoding' => @encoding))
      ::ActiveRecord::Base.establish_connection(config_.merge('schema_search_path' => 'public'))
      if (script_dir_ = config_['script_dir'])
        conn_ = ::ActiveRecord::Base.connection
        search_path_ = config_["schema_search_path"].to_s.strip
        search_path_ = search_path_.split(",").map{ |sp_| sp_.strip }
        if search_path_.include?('postgis')
          conn_.execute('CREATE SCHEMA postgis')
          conn_.execute('SET search_path TO postgis')
        end
        conn_.execute(::File.read(::File.expand_path('postgis.sql', script_dir_)))
        conn_.execute(::File.read(::File.expand_path('spatial_ref_sys.sql', script_dir_)))
      end
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
    ::ActiveRecord::Base.establish_connection(config_.merge('database' => 'postgres', 'schema_search_path' => 'public'))
    ::ActiveRecord::Base.connection.drop_database(config_['database'])
  else
    drop_database_without_postgis(config_)
  end
end


::RGeo::ActiveRecord::TaskHacker.modify('db:charset', nil, 'postgis') do |config_|
  ::ActiveRecord::Base.establish_connection(config_)
  puts(::ActiveRecord::Base.connection.encoding)
end


::RGeo::ActiveRecord::TaskHacker.modify('db:structure:dump', nil, 'postgis') do |config_|
  ::ENV['PGHOST'] = config_["host"] if config_["host"]
  ::ENV['PGPORT'] = config_["port"].to_s if config_["port"]
  ::ENV['PGPASSWORD'] = config_["password"].to_s if config_["password"]
  search_path_ = config_["schema_search_path"].to_s.strip
  search_path_ = search_path_.split(",").map{ |sp_| sp_.strip }
  search_path_.delete('postgis')
  search_path_ = ['public'] if search_path_.length == 0
  search_path_ = search_path_.map{ |sp_| "--schema=#{sp_}" }.join(" ")
  `pg_dump -i -U "#{config_["username"]}" -s -x -O -f db/#{::Rails.env}_structure.sql #{search_path_} #{config_["database"]}`
  raise "Error dumping database" if $?.exitstatus == 1
end


::RGeo::ActiveRecord::TaskHacker.modify('db:test:clone_structure', 'test', 'postgis') do |config_|
  ::ENV['PGHOST'] = config_["host"] if config_["host"]
  ::ENV['PGPORT'] = config_["port"].to_s if config_["port"]
  ::ENV['PGPASSWORD'] = config_["password"].to_s if config_["password"]
  `psql -U "#{config_["username"]}" -f #{::Rails.root}/db/#{::Rails.env}_structure.sql #{config_["database"]}`
end


::RGeo::ActiveRecord::TaskHacker.modify('db:test:purge', 'test', 'postgis') do |config_|
  ::ActiveRecord::Base.clear_active_connections!
  drop_database(config_)
  create_database(config_)
end
