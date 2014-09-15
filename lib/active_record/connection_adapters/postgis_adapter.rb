# The activerecord-postgis-adapter gem installs the *postgis*
# connection adapter into ActiveRecord.

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      # The name returned by #adapter_name
      ADAPTER_NAME = 'PostGIS'.freeze
    end
  end
end

# :stopdoc:

require 'active_record'
require 'active_record/connection_adapters/postgresql_adapter'
require 'rgeo/active_record'

require 'active_record/connection_adapters/postgis/version'
require 'active_record/connection_adapters/postgis/common_adapter_methods'
require 'active_record/connection_adapters/postgis/main_adapter'
require 'active_record/connection_adapters/postgis/spatial_column_info'
require 'active_record/connection_adapters/postgis/spatial_table_definition'
require 'active_record/connection_adapters/postgis/spatial_column'
require 'arel/visitors/postgis'
require 'active_record/connection_adapters/postgis/setup'
require 'active_record/connection_adapters/postgis/create_connection'
require 'active_record/connection_adapters/postgis/postgis_database_tasks'

::ActiveRecord::ConnectionAdapters::PostGIS.initial_setup

if defined?(::Rails::Railtie)
  load ::File.expand_path('postgis/railtie.rb', ::File.dirname(__FILE__))
end

# :startdoc:
