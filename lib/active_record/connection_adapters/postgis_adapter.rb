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

require 'active_record/connection_adapters/postgis_adapter/version.rb'
require 'active_record/connection_adapters/postgis_adapter/common_adapter_methods.rb'
require 'active_record/connection_adapters/postgis_adapter/main_adapter.rb'
require 'active_record/connection_adapters/postgis_adapter/spatial_table_definition.rb'
require 'active_record/connection_adapters/postgis_adapter/spatial_column.rb'
require 'active_record/connection_adapters/postgis_adapter/arel_tosql.rb'
require 'active_record/connection_adapters/postgis_adapter/setup.rb'
require 'active_record/connection_adapters/postgis_adapter/create_connection'
require 'active_record/connection_adapters/postgis_adapter/postgis_database_tasks.rb'

::ActiveRecord::ConnectionAdapters::PostGISAdapter.initial_setup

if defined?(::Rails::Railtie)
  load ::File.expand_path('postgis_adapter/railtie.rb', ::File.dirname(__FILE__))
end

# :startdoc:
