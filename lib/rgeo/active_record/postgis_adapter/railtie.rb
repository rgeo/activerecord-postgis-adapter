puts 'WARNING: requiring "rgeo/active_record/postgis_adapter/railtie" is deprecated. Generally, the normal Bundle.require will do the trick. If you need to require the railtie explicitly, require "active_record/connection_adapters/postgis_adapter/railtie"'

require 'active_record/connection_adapters/postgis_adapter/railtie'
