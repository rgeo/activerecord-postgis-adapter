if RUBY_ENGINE == "jruby"
  require "active_record/connection_adapters/jdbcpostgresql_adapter"
else
  require "pg"
end

module ActiveRecord  # :nodoc:
  module ConnectionHandling  # :nodoc:
    if RUBY_ENGINE == "jruby"

      def postgis_connection(config)
        config[:adapter_class] = ConnectionAdapters::PostGISAdapter
        postgresql_connection(config)
      end

      alias_method :jdbcpostgis_connection, :postgis_connection

    else

      # Based on the default <tt>postgresql_connection</tt> definition from ActiveRecord.
      # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/connection_adapters/postgresql_adapter.rb
      # FULL REPLACEMENT because we need to create a different class.
      def postgis_connection(config)
        conn_params = config.symbolize_keys

        conn_params.delete_if { |_, v| v.nil? }

        # Map ActiveRecords param names to PGs.
        conn_params[:user] = conn_params.delete(:username) if conn_params[:username]
        conn_params[:dbname] = conn_params.delete(:database) if conn_params[:database]

        # Forward only valid config params to PGconn.connect.
        valid_conn_param_keys = PGconn.conndefaults_hash.keys + [:requiressl]
        conn_params.slice!(*valid_conn_param_keys)

        # The postgres drivers don't allow the creation of an unconnected PGconn object,
        # so just pass a nil connection object for the time being.
        ConnectionAdapters::PostGISAdapter.new(nil, logger, conn_params, config)
      end

    end
  end
end
