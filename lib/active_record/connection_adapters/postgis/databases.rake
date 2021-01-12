# frozen_string_literal: true

namespace :db do
  namespace :gis do
    desc 'Setup PostGIS data in the database'
    task setup: [:load_config] do
      environments = [Rails.env]
      environments << 'test' if Rails.env.development?
      environments.each do |environment|
        ActiveRecord::Base.configurations
                          .configs_for(env_name: environment)
                          .reject { |env| env.configuration_hash['database'].blank? }
                          .each do |env|
          ActiveRecord::ConnectionAdapters::PostGIS::PostGISDatabaseTasks.new(env).setup_gis
        end
      end
    end
  end
end
