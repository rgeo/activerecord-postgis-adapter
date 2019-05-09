# frozen_string_literal: true

namespace :db do
  namespace :gis do
    desc "Setup PostGIS data in the database"
    task setup: [:load_config] do
      environments = [Rails.env]
      environments << "test" if Rails.env.development?
      if ActiveRecord::VERSION::MAJOR < 6
        ActiveRecord::Base.configurations
          .values_at(*environments)
          .compact
          .reject { |config| config["database"].blank? }
          .each do |config|
            ActiveRecord::ConnectionAdapters::PostGIS::PostGISDatabaseTasks.new(config).setup_gis
          end
      else
        environments.each do |environment|
          ActiveRecord::Base.configurations
            .configs_for(env_name: environment)
            .reject { |db_config| db_config.config["database"].blank? }
            .each do |db_config|
              ActiveRecord::ConnectionAdapters::PostGIS::PostGISDatabaseTasks.new(db_config.config).setup_gis
            end
        end
      end
    end
  end
end
