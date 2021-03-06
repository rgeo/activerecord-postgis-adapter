# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require "mocha/minitest"
require "activerecord-postgis-adapter"
require "erb"
require "byebug" if ENV["BYEBUG"]

module ActiveRecord
  class Base
    DATABASE_CONFIG_PATH = File.dirname(__FILE__) << "/database.yml"

    def self.test_connection_hash
      YAML.load(ERB.new(File.read(DATABASE_CONFIG_PATH)).result)
    end

    def self.establish_test_connection
      establish_connection test_connection_hash
    end
  end
end

ActiveRecord::Base.establish_test_connection

class SpatialModel < ActiveRecord::Base
  establish_test_connection
end

module ActiveSupport
  class TestCase
    self.test_order = :sorted

    def database_version
      @database_version ||= SpatialModel.connection.select_value("SELECT version()")
    end

    def postgis_version
      @postgis_version ||= SpatialModel.connection.select_value("SELECT postgis_lib_version()")
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

    def reset_spatial_store
      spatial_factory_store.clear
      spatial_factory_store.default = nil
    end
  end
end
