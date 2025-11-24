# frozen_string_literal: true

require "bundler/setup"
Bundler.require :development
require "minitest/autorun"
require "minitest/pride"
require "minitest/excludes"

require "erb"
require "byebug" if ENV["BYEBUG"]
require "activerecord-postgis-adapter"
require "timeout"

TRIAGE_MSG = "Needs triage and fixes. See #378"

ENV["ARCONN"] ||= "postgis"

# We need to require this before the original `cases/helper`
# to make sure we patch load schema before it runs.
require "support/load_schema_helper"

module LoadSchemaHelperExt
  # Postgis uses the postgresql specific schema.
  # We need to explicit that behavior.
  def load_postgis_specific_schema
    # silence verbose schema loading
    shh do
      load SCHEMA_ROOT + "/postgresql_specific_schema.rb"

      ActiveRecord::FixtureSet.reset_cache
    end
  end

  def load_schema
    super
    load_postgis_specific_schema
  end

  private def shh
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = original_stdout
  end
end
LoadSchemaHelper.prepend(LoadSchemaHelperExt)

require "cases/helper"

class SpatialModel < ActiveRecord::Base
end

module TestTimeoutHelper
  def time_it
    t0 = Minitest.clock_time

    timeout = ENV.fetch("TEST_TIMEOUT", 10).to_i
    Timeout.timeout(timeout, Timeout::Error, "Test took over #{timeout} seconds to finish") do
      yield
    end
  ensure
    self.time = Minitest.clock_time - t0
  end
end

module ActiveSupport
  class TestCase
    include TestTimeoutHelper

    def factory(srid: 3785)
      RGeo::Cartesian.preferred_factory(srid: srid)
    end

    def geographic_factory
      RGeo::Geographic.spherical_factory(srid: 4326)
    end

    # TODO: rather than using this, we should somehow make this a
    #   fixture that has its self-handled lifecycle. Right now we
    #   are depending on the dev running `reset_spatial_store` if
    #   they made any update. They can forget it (with the current
    #   flaky tests we have, it seems that is actually the case).
    def spatial_factory_store
      RGeo::ActiveRecord::SpatialFactoryStore.instance
    end

    def reset_spatial_store
      spatial_factory_store.clear
      spatial_factory_store.default = nil
    end
  end
end
