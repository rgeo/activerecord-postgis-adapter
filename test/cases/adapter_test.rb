require_relative 'test_helper'

class AdapterTest < ActiveSupport::TestCase
  def test_rgeo_extension
    assert RGeo::Geos.supported?
  end

  def test_ignore_tables
    assert_includes ActiveRecord::SchemaDumper.ignore_tables, 'geometry_columns'
    assert_includes ActiveRecord::SchemaDumper.ignore_tables, 'spatial_ref_sys'
    assert_includes ActiveRecord::SchemaDumper.ignore_tables, 'layer'
    assert_includes ActiveRecord::SchemaDumper.ignore_tables, 'topology'
  end

  def test_version
    refute_nil ActiveRecord::ConnectionAdapters::PostGIS::VERSION
  end

  def test_postgis_available
    assert_equal 'PostGIS', connection.adapter_name
    refute_nil connection.postgis_lib_version
  end

  def test_type_to_sql_should_ignore_srid_for_geographic_typ
    assert_equal 'Geography()', connection.type_to_sql(:st_geography, 666)
    assert_equal 'Geography(Point)', connection.type_to_sql(:st_point, 26191, true)
    assert_equal 'Geography(Polygon)', connection.type_to_sql(:st_polygon, 26192, true)
  end

  def test_type_to_sql_point
    assert_equal 'Geometry(Point,3758)', connection.type_to_sql(:st_point, 3758)
    assert_equal 'Geometry(PointZ,3758)', connection.type_to_sql(:st_point_z, 3758)
    assert_equal 'Geometry(PointM,3758)', connection.type_to_sql(:st_point_m, 3758)
    assert_equal 'Geometry(PointZM)', connection.type_to_sql(:st_point_z_m)
  end

  def test_type_to_sql_polygon
    assert_equal 'Geometry(Polygon,3758)', connection.type_to_sql(:st_polygon, 3758)
    assert_equal 'Geometry(PolygonZ,3758)', connection.type_to_sql(:st_polygon_z, 3758)
    assert_equal 'Geometry(PolygonM,3758)', connection.type_to_sql(:st_polygon_m, 3758)
    assert_equal 'Geometry(PolygonZM,3758)', connection.type_to_sql(:st_polygon_z_m, 3758)
  end

  def test_type_to_sql_geometry
    assert_equal 'Geometry(Polygon,3758)', connection.type_to_sql(:st_polygon, 3758)
    assert_equal 'Geometry(PolygonZ,3758)', connection.type_to_sql(:st_polygon_z, 3758)
    assert_equal 'Geometry(PolygonM,3758)', connection.type_to_sql(:st_polygon_m, 3758)
    assert_equal 'Geometry(PolygonZM,3758)', connection.type_to_sql(:st_polygon_z_m, 3758)
  end
end
