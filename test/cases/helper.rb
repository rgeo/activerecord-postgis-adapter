begin
  require 'byebug'
rescue LoadError
  # ignore
end

require 'active_support/testing/autorun'
require 'activerecord-postgis-adapter'

require 'support/connection'
require 'models/city'

ARTest.connect
ActiveRecord::Base.connection.enable_extension 'postgis'
ARTest.load_schema