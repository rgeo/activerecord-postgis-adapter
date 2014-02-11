module ActiveRecord  # :nodoc:

  module ConnectionHandling  # :nodoc:


    if defined?(::RUBY_ENGINE) && ::RUBY_ENGINE == 'jruby'

      require 'active_record/connection_adapters/jdbcpostgresql_adapter'
      require 'active_record/connection_adapters/postgis_adapter/shared/jdbc_compat'


      def postgis_connection(config_)
        ::ActiveRecord::ConnectionAdapters::PostGISAdapter.create_jdbc_connection(self, config_)
      end

      alias_method :jdbcpostgis_connection, :postgis_connection


    else


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

end
