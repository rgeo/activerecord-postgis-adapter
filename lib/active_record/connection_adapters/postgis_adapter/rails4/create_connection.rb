module ActiveRecord  # :nodoc:

  module ConnectionHandling  # :nodoc:
    require 'pg'

    # Based on the default <tt>postgresql_connection</tt> definition from
    # ActiveRecord.

    def postgis_connection(config_)
      # FULL REPLACEMENT because we need to create a different class.
      conn_params_ = config_.symbolize_keys

      conn_params_.delete_if { |_, v_| v_.nil? }

      # Map ActiveRecords param names to PGs.
      conn_params_[:user] = conn_params_.delete(:username) if conn_params_[:username]
      conn_params_[:dbname] = conn_params_.delete(:database) if conn_params_[:database]

      # Forward only valid config params to PGconn.connect.
      conn_params_.keep_if { |k_, _| VALID_CONN_PARAMS.include?(k_) }

      # The postgres drivers don't allow the creation of an unconnected PGconn object,
      # so just pass a nil connection object for the time being.
      ::ActiveRecord::ConnectionAdapters::PostGISAdapter::MainAdapter.new(nil, logger, conn_params_, config_)
    end

  end

end
