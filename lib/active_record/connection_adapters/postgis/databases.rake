namespace :db do
  namespace :gis do
    desc "Setup PostGIS data in the database"
    task setup: [:load_config] do
      environments = [Rails.env]
      environments << "test" if Rails.env.development?
      ActiveRecord::Base.configurations
        .values_at(*environments)
        .compact
        .reject{ |config| config["database"].blank? }
        .each do |config|
          ActiveRecord::ConnectionAdapters::PostGIS::PostGISDatabaseTasks.new(config).setup_gis
        end
    end
  end
end
