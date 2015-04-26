# The activerecord-postgis-adapter gem installs the *postgis*
# connection adapter into ActiveRecord.

# :stopdoc:

require 'active_record/connection_adapters/postgresql_adapter'
require 'rgeo/active_record'
require 'active_record/connection_adapters/postgis_adapter/version'
require 'active_record/connection_adapters/postgis_adapter/schema_statements'
require 'active_record/connection_adapters/postgis_adapter/main_adapter'
require 'active_record/connection_adapters/postgis_adapter/spatial_column_info'
require 'active_record/connection_adapters/postgis_adapter/spatial_table_definition'
require 'active_record/connection_adapters/postgis_adapter/spatial_column'
require 'active_record/connection_adapters/postgis_adapter/arel_tosql'
require 'active_record/connection_adapters/postgis_adapter/setup'
require 'active_record/connection_adapters/postgis_adapter/oid/spatial'
require 'active_record/connection_adapters/postgis_adapter/create_connection'
require 'active_record/connection_adapters/postgis_adapter/postgis_database_tasks'


::ActiveRecord::ConnectionAdapters::PostGISAdapter.initial_setup

if defined?(::Rails::Railtie)
  load ::File.expand_path('postgis_adapter/railtie.rb', ::File.dirname(__FILE__))
end

# :startdoc:
