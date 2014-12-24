begin
  require 'pry-byebug'
rescue LoadError
  # ignore
end

require 'active_support/testing/autorun'
require_relative '../../lib/activerecord-postgis-adapter'
ActiveSupport.test_order = :random

require_relative '../support/connection'
require_relative '../models/geometry'

def connection
  ActiveRecord::Base.connection
end

def columns
  klass.columns
end

def indexes
  connection.indexes(klass.table_name)
end

def get_column_definition(name)
  columns.select{|x| x.name == name}.first
end

def get_table_index(name)
  indexes.select{|x| x.name == name}.first
end


ARTest.connect
connection.enable_extension('postgis')
ARTest.load_schema
