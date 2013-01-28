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


require 'active_record/connection_adapters/jdbcpostgresql_adapter'

# Extend JDBC's PostgreSQLAdapter implementation for compatibility with
# ActiveRecord's default PostgreSQLAdapter.
class ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
  # Add `query` method for compatibility
  def query(*args)
    select_rows(*args)
  end

  # Backport from master, so PostGIS adapater will work with current stable
  # activerecord-jdbc-adapter gem.
  #
  # https://github.com/jruby/activerecord-jdbc-adapter/pull/200
  unless method_defined?(:schema_search_path=)
    def schema_search_path=(schema_csv)
      if schema_csv
        execute "SET search_path TO #{schema_csv}"
        @schema_search_path = schema_csv
      end
    end
  end

  # Backport from master, so PostGIS adapater will work with current stable
  # activerecord-jdbc-adapter gem.
  #
  # https://github.com/jruby/activerecord-jdbc-adapter/pull/200
  unless method_defined?(:schema_search_path)
    # Returns the active schema search path.
    def schema_search_path
      @schema_search_path ||= exec_query('SHOW search_path', 'SCHEMA')[0]['search_path']
    end
  end

  # For ActiveRecord 3.1 compatibility: Add the "postgis" adapter to the
  # matcher of jdbc-like adapters.
  def self.visitor_for(pool)
    config = pool.spec.config
    adapter = config[:adapter]
    adapter_spec = config[:adapter_spec] || self
    if adapter =~ /^(jdbc|jndi|postgis)$/
      adapter_spec.arel2_visitors(config).values.first.new(pool)
    else
      adapter_spec.arel2_visitors(config)[adapter].new(pool)
    end
  end
end

class ::ActiveRecord::Base
  # ActiveRecord looks for the postgis_connection factory method in
  # this class.
  #
  # Based on the default `postgresql_connection` definition from
  # activerecord-jdbc-adapter's:
  # lib/arjdbc/postgresql/connection_methods.rb
  def self.postgis_connection(config)
    require "arjdbc/postgresql"
    config[:host] ||= "localhost"
    config[:port] ||= 5432
    config[:url] ||= "jdbc:postgresql://#{config[:host]}:#{config[:port]}/#{config[:database]}"
    config[:url] << config[:pg_params] if config[:pg_params]
    config[:driver] ||= "org.postgresql.Driver"
    config[:adapter_class] = ::ActiveRecord::ConnectionAdapters::PostGISAdapter::MainAdapter
    config[:adapter_spec] = ::ArJdbc::PostgreSQL
    conn = jdbc_connection(config)
    conn.execute("SET SEARCH_PATH TO #{config[:schema_search_path]}") if config[:schema_search_path]
    conn
  end
end
