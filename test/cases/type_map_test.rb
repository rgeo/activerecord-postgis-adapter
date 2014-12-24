require_relative 'test_helper'

class TypeMapTest < ActiveSupport::TestCase
  def test_geometry
    type = connection.type_map.lookup 'geometry', '', 'Geometry(Point)'
    assert_instance_of ActiveRecord::ConnectionAdapters::PostGIS::OID::STGeometry , type
  end

  def test_geography
    type = connection.type_map.lookup 'geography', '', 'Geography(Point)'
    assert_instance_of ActiveRecord::ConnectionAdapters::PostGIS::OID::STGeography , type
  end
end