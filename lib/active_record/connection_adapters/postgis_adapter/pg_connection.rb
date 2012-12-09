require 'active_record/connection_adapters/postgresql_adapter'

class ::ActiveRecord::Base
  # ActiveRecord looks for the postgis_connection factory method in
  # this class.
  #
  # Based on the default `postgresql_connection` definition from
  # activerecord's:
  # lib/active_record/connection_adapters/postgresql_adapter.rb
  def self.postgis_connection(config)
    config = config.symbolize_keys
    host     = config[:host]
    port     = config[:port] || 5432
    username = config[:username].to_s if config[:username]
    password = config[:password].to_s if config[:password]

    if config.key?(:database)
      database = config[:database]
    else
      raise ArgumentError, "No database specified. Missing argument: database."
    end

    # The postgres drivers don't allow the creation of an unconnected PGconn object,
    # so just pass a nil connection object for the time being.
    ::ActiveRecord::ConnectionAdapters::PostGISAdapter::MainAdapter.new(nil, logger, [host, port, nil, nil, database, username, password], config)
  end
end
