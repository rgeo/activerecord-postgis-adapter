unless defined?(::ActiveRecord::ConnectionAdapters::PostGISAdapter::Railtie)
  module ActiveRecord  # :nodoc:
    module ConnectionAdapters  # :nodoc:
      module PostGISAdapter  # :nodoc:
        class Railtie < ::Rails::Railtie  # :nodoc:
          rake_tasks do
            load ::File.expand_path("../rails4/databases.rake", ::File.dirname(__FILE__))
          end
        end
      end
    end
  end
end
