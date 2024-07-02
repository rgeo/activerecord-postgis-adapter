# frozen_string_literal: true

require 'active_record'
require "active_record/connection_adapters"
ActiveRecord::ConnectionAdapters.register("postgis", "ActiveRecord::ConnectionAdapters::PostGISAdapter", "active_record/connection_adapters/postgis_adapter")
