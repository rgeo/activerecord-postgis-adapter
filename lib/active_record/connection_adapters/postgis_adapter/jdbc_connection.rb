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
  class << self
    # ActiveRecord looks for the postgis_connection factory method in
    # this class.
    #
    # Based on the default `postgresql_connection` definition from
    # activerecord-jdbc-adapter's:
    # lib/arjdbc/postgresql/connection_methods.rb
    def postgis_connection(config)
      begin
        require 'jdbc/postgres'
        ::Jdbc::Postgres.load_driver(:require) if defined?(::Jdbc::Postgres.load_driver)
      rescue LoadError # assuming driver.jar is on the class-path
      end
      require "arjdbc/postgresql"
      config[:username] ||= ::Java::JavaLang::System.get_property("user.name")
      config[:host] ||= "localhost"
      config[:port] ||= 5432
      config[:url] ||= "jdbc:postgresql://#{config[:host]}:#{config[:port]}/#{config[:database]}"
      config[:url] << config[:pg_params] if config[:pg_params]
      config[:driver] ||= defined?(::Jdbc::Postgres.driver_name) ? ::Jdbc::Postgres.driver_name : 'org.postgresql.Driver'
      config[:adapter_class] = ::ActiveRecord::ConnectionAdapters::PostGISAdapter::MainAdapter
      config[:adapter_spec] = ::ArJdbc::PostgreSQL
      conn = jdbc_connection(config)
      conn.execute("SET SEARCH_PATH TO #{config[:schema_search_path]}") if config[:schema_search_path]
      conn
    end
    alias_method :jdbcpostgis_connection, :postgis_connection
  end
end
