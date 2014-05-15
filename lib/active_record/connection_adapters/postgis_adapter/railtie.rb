require 'rails/railtie'
require 'active_record/connection_adapters/postgis_adapter'

unless defined?(::ActiveRecord::ConnectionAdapters::PostGISAdapter::Railtie)
  module ActiveRecord  # :nodoc:
    module ConnectionAdapters  # :nodoc:
      module PostGISAdapter  # :nodoc:
        class Railtie < ::Rails::Railtie  # :nodoc:
          rake_tasks do
            load ::File.expand_path("databases.rake", ::File.dirname(__FILE__))
          end
        end
      end
    end
  end
end

