require "active_record/connection_adapters/postgis_adapter.rb"

module ActiveRecord  # :nodoc:
  module ConnectionAdapters  # :nodoc:
    module PostGIS  # :nodoc:
      extend ActiveSupport::Autoload

      autoload :PostGISDatabaseTasks,
        'active_record/connection_adapters/postgis/postgis_database_tasks'
    end
  end
end
