# frozen_string_literal: true

require "active_record"
require "active_record/connection_adapters"
require "rgeo/active_record"

ActiveSupport.on_load(:active_record_postgresqladapter) do
  require "active_record/connection_adapters/postgis_adapter"
end
