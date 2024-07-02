# frozen_string_literal: true

module ActiveRecord  # :nodoc:
  module ConnectionHandling  # :nodoc:
    # Based on the default <tt>postgresql_connection</tt> definition from ActiveRecord.
    # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/connection_adapters/postgresql_adapter.rb
    # FULL REPLACEMENT because we need to create a different class.
    def postgis_connection(config)
      conn_params = config.symbolize_keys.compact

      # Map ActiveRecords param names to PGs.
      conn_params[:user] = conn_params.delete(:username) if conn_params[:username]
      conn_params[:dbname] = conn_params.delete(:database) if conn_params[:database]

      # Forward only valid config params to PG.connect
      valid_conn_param_keys = PG::Connection.conndefaults_hash.keys + [:requiressl]
      conn_params.slice!(*valid_conn_param_keys)

      ConnectionAdapters::PostGISAdapter.new(
        ConnectionAdapters::PostGISAdapter.new_client(conn_params),
        logger,
        conn_params,
        config
      )
    end
  end
end
