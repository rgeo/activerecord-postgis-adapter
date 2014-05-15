require 'pg'

module ActiveRecord  # :nodoc:
  module ConnectionHandling  # :nodoc:

    # Based on the default <tt>postgresql_connection</tt> definition from ActiveRecord.
    # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/connection_adapters/postgresql_adapter.rb
    def postgis_connection(config)
      # FULL REPLACEMENT because we need to create a different class.
      conn_params = config.symbolize_keys

      conn_params.delete_if { |_, v| v.nil? }

      # Map ActiveRecords param names to PGs.
      conn_params[:user] = conn_params.delete(:username) if conn_params[:username]
      conn_params[:dbname] = conn_params.delete(:database) if conn_params[:database]

      # Forward only valid config params to PGconn.connect.
      conn_params.keep_if { |k, _| VALID_CONN_PARAMS.include?(k) }

      # The postgres drivers don't allow the creation of an unconnected PGconn object,
      # so just pass a nil connection object for the time being.
      ::ActiveRecord::ConnectionAdapters::PostGISAdapter::MainAdapter.new(nil, logger, conn_params, config)
    end

  end
end
