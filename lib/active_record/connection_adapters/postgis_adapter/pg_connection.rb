require 'active_record/connection_adapters/postgresql_adapter'
require 'pg'

class ::ActiveRecord::Base
  # ActiveRecord looks for the postgis_connection factory method in
  # this class.
  #
  # Based on the default `postgresql_connection` definition from
  # activerecord's:
  # lib/active_record/connection_adapters/postgresql_adapter.rb
  def self.postgis_connection(config_)
    config_ = config_.symbolize_keys
    host_ = config_[:host]
    port_ = config_[:port] || 5432
    username_ = config_[:username].to_s if config_[:username]
    password_ = config_[:password].to_s if config_[:password]

    if config_.key?(:database)
      database_ = config_[:database]
    else
      raise ::ArgumentError, "No database specified. Missing argument: database."
    end

    # The postgres drivers don't allow the creation of an unconnected PGconn object,
    # so just pass a nil connection object for the time being.
    ::ActiveRecord::ConnectionAdapters::PostGISAdapter::MainAdapter.new(nil, logger, [host_, port_, nil, nil, database_, username_, password_], config_)
  end
end
