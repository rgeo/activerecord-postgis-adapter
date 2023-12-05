# frozen_string_literal: true

require "bundler/setup"
Bundler.require :development
require "minitest/autorun"
require "minitest/pride"
require "mocha/minitest"
require "erb"
require "byebug" if ENV["BYEBUG"]
require "activerecord-postgis-adapter"

if ENV["ARCONN"]
  # only install activerecord schema if we need it
  require "cases/helper"

  def load_postgis_specific_schema
    original_stdout = $stdout
    $stdout = StringIO.new

    load "schema/postgis_specific_schema.rb"

    ActiveRecord::FixtureSet.reset_cache
  ensure
    $stdout = original_stdout
  end

  load_postgis_specific_schema

  module ARTestCaseOverride
    def with_postgresql_datetime_type(type)
      adapter = ActiveRecord::ConnectionAdapters::PostGISAdapter
      adapter.remove_instance_variable(:@native_database_types) if adapter.instance_variable_defined?(:@native_database_types)
      datetime_type_was = adapter.datetime_type
      adapter.datetime_type = type
      yield
    ensure
      adapter = ActiveRecord::ConnectionAdapters::PostGISAdapter
      adapter.datetime_type = datetime_type_was
      adapter.remove_instance_variable(:@native_database_types) if adapter.instance_variable_defined?(:@native_database_types)
    end
  end

  ActiveRecord::TestCase.prepend(ARTestCaseOverride)
else
  module ActiveRecord
    class Base
      DATABASE_CONFIG_PATH = File.dirname(__FILE__) << "/database.yml"

      def self.test_connection_hash
        conns = YAML.load(ERB.new(File.read(DATABASE_CONFIG_PATH)).result)
        conn_hash = conns["connections"]["postgis"]["arunit"]
        conn_hash.merge(adapter: "postgis")
      end

      def self.establish_test_connection
        establish_connection test_connection_hash
      end
    end
  end

  ActiveRecord::Base.establish_test_connection
end

class SpatialModel < ActiveRecord::Base
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

    def factory(srid: 3785)
      RGeo::Cartesian.preferred_factory(srid: srid)
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
