module ActiveRecord  # :nodoc:
  module ConnectionAdapters  # :nodoc:
    module PostGIS  # :nodoc:
      class Railtie < ::Rails::Railtie  # :nodoc:
        rake_tasks do
          load "active_record/connection_adapters/postgis/databases.rake"
        end
      end
    end
  end
end
