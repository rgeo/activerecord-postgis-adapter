# The activerecord-postgis-adapter gem installs the *postgis*
# connection adapter into ActiveRecord.

module ActiveRecord
  module ConnectionAdapters
    module PostGISAdapter
      # The name returned by #adapter_name
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
