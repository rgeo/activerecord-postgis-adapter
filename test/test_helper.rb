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

    load SCHEMA_ROOT + "/postgresql_specific_schema.rb"

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
      DATABASE_CONFIG_PATH = __dir__ + "/database.yml"

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
end # end if ENV["ARCONN"]

class SpatialModel < ActiveRecord::Base
end

require 'timeout'
require 'stackprof'

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


# module DebugSlowTests
# 	def wrap_the_thing(name)
# 		rv = nil
# 		t0 = Minitest.clock_time
# 		profile = StackProf.run(mode: :wall, interval: 1000) do
# 			rv = yield
# 		end
# 		puts
# 		puts "#{name} took #{Minitest.clock_time - t0} seconds"
# 		puts
# 		pp SpatialModel.lease_connection.instance_variable_get(:@raw_connection).conninfo_hash
# 		puts
# 		StackProf::Report.new(profile).print_text
# 		rv
# 	end
# 	def enable_extension!(...)
# 		wrap_the_thing(__method__) do
# 			super
# 		end
# 	end

# 	def disable_extension!(...)
# 		wrap_the_thing(__method__) do
# 			super
# 		end
# 	end
# end



module ActiveRecord
  class TestCase
    include TestTimeoutHelper
    # include DebugSlowTests
    # extend DebugSlowTests

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

# conn = SpatialModel.lease_connection.instance_variable_get(:@raw_connection)
# $count = conn.conninfo_hash[:port].count(",")+1

# TracePoint.trace(:call) do |tp|
# 	conn = SpatialModel.lease_connection.instance_variable_get(:@raw_connection)
# 	count = conn.conninfo_hash[:port].count(",")+1
# 	next if count == $count

# 	$count = count
# 	puts "port(count=#{count}): #{conn.conninfo_hash[:port][0, 100]}"
# end

module DebugReset
	def reset

		iopts = conninfo_hash.compact
		puts "host count before: #{iopts[:host].count(",") + 1}"
		if iopts[:host] && !iopts[:host].empty? && PG.library_version >= 100000
			iopts = self.class.send(:resolve_hosts, iopts)
		end
		puts "host count after: #{iopts[:host].count(",") + 1}"
		conninfo = self.class.parse_connect_args( iopts );
		reset_start2(conninfo)
		async_connect_or_reset(:reset_poll)
		self
	end
end

module DebugResolve
def resolve_hosts(iopts)
		host = iopts[:host]
		host = host[0, 97] + "..." if host.length > 100
		puts "resolve_hosts, hosts: #{host.inspect}"

		port = iopts[:port]
		port = port[0, 97] + "..." if port.length > 100
		puts "resolve_hosts, ports: #{port.inspect}"

		super
	end
end

PG::Connection.prepend(DebugReset)
PG::Connection.singleton_class.prepend(DebugResolve)
