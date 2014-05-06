# The activerecord-postgis-adapter gem installs the *postgis*
# connection adapter into ActiveRecord.

module ActiveRecord
  # All ActiveRecord adapters go in this namespace.
  # This adapter is installed into the PostGISAdapter submodule.
  module ConnectionAdapters
    # The PostGIS Adapter lives in this namespace.
    module PostGISAdapter
      # The name returned by the adapter_name method of this adapter.
      ADAPTER_NAME = 'PostGIS'.freeze
    end
  end
end

# :stopdoc:

require 'active_record'
require 'active_record/connection_adapters/postgresql_adapter'
require 'rgeo/active_record'

case ::ActiveRecord::VERSION::MAJOR
when 4
  require 'active_record/connection_adapters/postgis_adapter/version.rb'
  require 'active_record/connection_adapters/postgis_adapter/shared/common_adapter_methods.rb'
  require 'active_record/connection_adapters/postgis_adapter/rails4/main_adapter.rb'
  require 'active_record/connection_adapters/postgis_adapter/rails4/spatial_table_definition.rb'
  require 'active_record/connection_adapters/postgis_adapter/rails4/spatial_column.rb'
  require 'active_record/connection_adapters/postgis_adapter/shared/arel_tosql.rb'
  require 'active_record/connection_adapters/postgis_adapter/shared/setup.rb'
  require 'active_record/connection_adapters/postgis_adapter/rails4/create_connection'
  require 'active_record/connection_adapters/postgis_adapter/rails4/postgis_database_tasks.rb'
else
  raise "Unsupported ActiveRecord version #{::ActiveRecord::VERSION::STRING}"
end

::ActiveRecord::ConnectionAdapters::PostGISAdapter.initial_setup

if defined?(::Rails::Railtie)
  load ::File.expand_path('postgis_adapter/shared/railtie.rb', ::File.dirname(__FILE__))
end

# :startdoc:
