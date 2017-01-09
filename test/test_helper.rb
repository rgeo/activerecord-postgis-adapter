require "minitest/autorun"
require "minitest/pride"
require "mocha/mini_test"
require "active_record"
require "activerecord-postgis-adapter"

begin
  require "byebug"
rescue LoadError
  # ignore
end

class ActiveSupport::TestCase
  self.test_order = :sorted

  DATABASE_CONFIG_PATH = File.dirname(__FILE__) << "/database.yml"

  class SpatialModel < ActiveRecord::Base
    establish_connection YAML.load_file(DATABASE_CONFIG_PATH)
  end

  def factory
    RGeo::Cartesian.preferred_factory(srid: 3785)
  end

  def geographic_factory
    RGeo::Geographic.spherical_factory(srid: 4326)
  end

  def spatial_factory_store
    RGeo::ActiveRecord::SpatialFactoryStore.instance
  end
end
