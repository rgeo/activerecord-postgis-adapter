require_relative 'test_helper'

class DDLTest < ActiveSupport::TestCase
  def test_create_point
    col = get_column_definition('point')
    assert_equal(RGeo::Feature::Point, col.spatial_type)
  end

  def test_create_geographic_point
    col  = get_column_definition('geographic_point')
    assert_equal(RGeo::Feature::Point, col.spatial_type)
    assert(col.geographic?)
    assert_equal(4326, col.srid)
  end

  def test_create_linestring
    col  = get_column_definition('linestring_with_srid')
    assert_equal(RGeo::Feature::LineString, col.spatial_type)
    assert_equal(3785, col.srid)
  end

  def test_create_polygonz
    col  = get_column_definition('polygonz_with_srid')
    assert_equal(RGeo::Feature::Polygon, col.spatial_type)
    assert_equal(3785, col.srid)
  end

  def test_create_polygonzm
    col  = get_column_definition('polygonzm_with_srid')
    assert_equal(RGeo::Feature::Polygon, col.spatial_type)
    assert_equal(3785, col.srid)
  end

  def test_create_geometry_without_srid
    col  = get_column_definition('geometry_without_srid')
    assert_equal(RGeo::Feature::Geometry, col.spatial_type)
    assert_equal(0, col.srid)
  end

  def test_create_geometry_with_srid
    col  = get_column_definition('geometry_with_srid')
    assert_equal(RGeo::Feature::Geometry, col.spatial_type)
    assert_equal(3785, col.srid)
  end

  private
    def klass
      Geometry
    end

end
