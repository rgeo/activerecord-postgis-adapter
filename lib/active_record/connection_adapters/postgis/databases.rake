# :stopdoc:

namespace :db do
  namespace :gis do
    desc "Setup PostGIS data in the database"
    task :setup => [:load_config] do
      environments_ = [::Rails.env]
      environments_ << 'test' if ::Rails.env.development?
      configs_ = ::ActiveRecord::Base.configurations.values_at(*environments_).compact.reject{ |config_| config_['database'].blank? }
      configs_.each do |config_|
        ::ActiveRecord::ConnectionAdapters::PostGIS::PostGISDatabaseTasks.new(config_).setup_gis
      end
    end
  end
end

# :startdoc:
