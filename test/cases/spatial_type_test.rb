require_relative 'test_helper'

class SpatialTypeTest < ActiveSupport::TestCase
  def test_point_without_srid
    st_geom = ActiveRecord::ConnectionAdapters::PostGIS::OID::STGeometry.new('geometry(Point)')
    assert_equal 0, st_geom.srid
    assert_equal RGeo::Geos.factory(srid: 0), st_geom.factory
    refute st_geom.has_z?
    refute st_geom.has_m?
    refute st_geom.geographic?
  end

  def test_point_with_srid
    st_geom = ActiveRecord::ConnectionAdapters::PostGIS::OID::STGeometry.new('geometry(Point,3857)')
    assert_equal 3857, st_geom.srid
    assert_equal RGeo::Geos.factory(srid: 3857), st_geom.factory
    refute st_geom.has_z?
    refute st_geom.has_m?
  end

  def test_point_z_without_srid
    st_geom = ActiveRecord::ConnectionAdapters::PostGIS::OID::STGeometry.new('geometry(PointZ)')
    assert st_geom.has_z?
    refute st_geom.has_m?
  end

  def test_point_z_m_without_srid
    st_geom = ActiveRecord::ConnectionAdapters::PostGIS::OID::STGeometry.new('geometry(PointZM)')
    assert st_geom.has_z?
    assert st_geom.has_m?
  end

  def test_point_z_with_srid
    st_geom = ActiveRecord::ConnectionAdapters::PostGIS::OID::STGeometry.new('geometry(PointZM,3857)')
    assert st_geom.has_z?
    assert st_geom.has_m?
    assert_equal 3857, st_geom.srid
  end

  def test_point_z_m_with_srid
    st_geom = ActiveRecord::ConnectionAdapters::PostGIS::OID::STGeometry.new('geometry(PointZM,3857)')
    assert st_geom.has_z?
    assert st_geom.has_m?
    assert_equal 3857, st_geom.srid
  end

  # Geo
  def test_geo_point
    st_geog = ActiveRecord::ConnectionAdapters::PostGIS::OID::STGeography.new('geography(Point)')
    assert_equal 4326, st_geog.srid
    assert_equal RGeo::Geographic.spherical_factory, st_geog.factory
    refute st_geog.has_z?
    refute st_geog.has_m?
    assert st_geog.precision
    assert st_geog.geographic?
  end

  def test_geo_point_z
    st_geog = ActiveRecord::ConnectionAdapters::PostGIS::OID::STGeography.new('geography(PointZ)')
    assert_equal :st_point_z, st_geog.type
    assert st_geog.has_z?
    refute st_geog.has_m?
    assert st_geog.precision
    assert st_geog.geographic?
  end

  def test_geo_point_z_m
    st_geog = ActiveRecord::ConnectionAdapters::PostGIS::OID::STGeography.new('geography(PointZM)')
    assert_equal :st_point_z_m, st_geog.type
    assert st_geog.has_z?
    assert st_geog.has_m?
    assert st_geog.precision
    assert st_geog.geographic?
  end
end