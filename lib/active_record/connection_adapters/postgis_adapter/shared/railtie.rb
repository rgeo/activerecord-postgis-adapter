unless defined?(::ActiveRecord::ConnectionAdapters::PostGISAdapter::Railtie)

  module ActiveRecord  # :nodoc:

    module ConnectionAdapters  # :nodoc:

      module PostGISAdapter  # :nodoc:


        class Railtie < ::Rails::Railtie  # :nodoc:

          rake_tasks do
            directory_ = case ::ActiveRecord::VERSION::MAJOR
              when 3 then 'rails3'
              when 4 then 'rails4'
              else raise "Unsupported ActiveRecord version #{::ActiveRecord::VERSION::STRING}"
            end
            load ::File.expand_path("../#{directory_}/databases.rake", ::File.dirname(__FILE__))
          end

        end


      end

    end

  end

end
