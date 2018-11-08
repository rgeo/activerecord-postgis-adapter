# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require "mocha/minitest"
require "activerecord-postgis-adapter"
require "erb"

begin
  require "byebug"
rescue LoadError
  # ignore
end

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

class SpatialModel < ActiveRecord::Base
  establish_test_connection
end

module ActiveSupport
  class TestCase
    self.test_order = :sorted

    def database_version
      @database_version ||= SpatialModel.connection.select_value("SELECT version()")
    end

    def pg_10?
      database_version.include?("PostgreSQL 10")
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
end
