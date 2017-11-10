require "test_helper"

class TypeTest < ActiveSupport::TestCase
  def test_parse_simple_type
    assert_equal ["geometry", 0, false, false], spatial.parse_sql_type("geometry")
    assert_equal ["geography", 0, false, false], spatial.parse_sql_type("geography")
  end

  def test_parse_geo_type
    assert_equal ["Point", 0, false, false], spatial.parse_sql_type("geography(Point)")
    assert_equal ["Polygon", 0, false, false], spatial.parse_sql_type("geography(Polygon)")
  end

  def test_parse_type_with_srid
    assert_equal ["Point", 4326, false, false], spatial.parse_sql_type("geography(Point,4326)")
    assert_equal ["Polygon", 4327, true, false], spatial.parse_sql_type("geography(PolygonZ,4327)")
    assert_equal ["Point", 4328, false, true], spatial.parse_sql_type("geography(PointM,4328)")
    assert_equal ["Point", 4329, true, true], spatial.parse_sql_type("geography(PointZM,4329)")
    assert_equal ["MultiPolygon", 4326, false, false], spatial.parse_sql_type("geometry(MultiPolygon,4326)")
  end

  def test_parse_non_geo_types
    assert_equal ["x", 0, false, false], spatial.parse_sql_type("x")
    assert_equal ["foo", 0, false, false], spatial.parse_sql_type("foo")
    assert_equal ["foo(A,1234)", 0, false, false], spatial.parse_sql_type("foo(A,1234)")
  end

  private

  def spatial
    ActiveRecord::ConnectionAdapters::PostGIS::OID::Spatial
  end
end
