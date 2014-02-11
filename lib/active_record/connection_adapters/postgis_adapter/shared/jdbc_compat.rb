module ActiveRecord  # :nodoc:

  module ConnectionAdapters  # :nodoc:


    # Extend JDBC's PostgreSQLAdapter implementation for compatibility with
    # ActiveRecord's default PostgreSQLAdapter.

    class PostgreSQLAdapter  # :nodoc:


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


    module PostGISAdapter  # :nodoc:


      # Based on the default <tt>postgresql_connection</tt> definition from
      # activerecord-jdbc-adapter

      def self.create_jdbc_connection(context_, config_)
        begin
          require 'jdbc/postgres'
          ::Jdbc::Postgres.load_driver(:require) if defined?(::Jdbc::Postgres.load_driver)
        rescue LoadError # assuming driver.jar is on the class-path
        end
        require "arjdbc/postgresql"
        config_[:username] ||= ::Java::JavaLang::System.get_property("user.name")
        config_[:host] ||= "localhost"
        config_[:port] ||= 5432
        config_[:url] ||= "jdbc:postgresql://#{config_[:host]}:#{config_[:port]}/#{config_[:database]}"
        config_[:url] << config_[:pg_params] if config_[:pg_params]
        config_[:driver] ||= defined?(::Jdbc::Postgres.driver_name) ? ::Jdbc::Postgres.driver_name : 'org.postgresql.Driver'
        config_[:adapter_class] = ::ActiveRecord::ConnectionAdapters::PostGISAdapter::MainAdapter
        config_[:adapter_spec] = ::ArJdbc::PostgreSQL
        conn_ = context_.jdbc_connection(config_)
        conn_.execute("SET SEARCH_PATH TO #{config_[:schema_search_path]}") if config_[:schema_search_path]
        conn_
      end


    end


  end

end
