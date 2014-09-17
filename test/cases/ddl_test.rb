require_relative 'helper'

class DDLTest < ActiveSupport::TestCase # :nodoc:
  def test_create_simple_geometry
    col  = get_column_definition('latlon3785')
    assert_equal(RGeo::Feature::Point, col.geometric_type)
    assert_not col.geographic?
    assert_equal(3785, col.srid)
  end

  def test_create_point_geography
    col  = get_column_definition('latlon4326')
    assert_equal(::RGeo::Feature::Point, col.geometric_type)
    assert(col.geographic?)
    assert_equal(4326, col.srid)
  end
  #
  def test_create_geometry_with_index
    index = get_table_index('index_cities_on_latlon3785')
    assert_kind_of RGeo::ActiveRecord::SpatialIndexDefinition, index
  end



  def test_create_simple_geometry_using_shortcut
    col = get_column_definition('geometry_shortcut')
    assert_equal(RGeo::Feature::Geometry, col.geometric_type)
  end

  def test_create_simple_geography_using_shortcut
    col = get_column_definition('geography_shortcut')
    assert_equal(RGeo::Feature::Geometry, col.geometric_type)
    assert col.geographic?
    assert_equal(4326, col.srid)
  end
  #
  def test_create_point_geometry_using_shortcut
    col = get_column_definition('location')
    assert_equal(RGeo::Feature::Point, col.geometric_type)
  end

  def test_create_geometry_with_options
    col = get_column_definition('province')
    assert_equal(RGeo::Feature::Polygon, col.geometric_type)
    assert_not col.geographic?
    assert_not col.has_z
    assert col.has_m
    assert_equal(3785, col.srid)
    #TODO REMOVE
    assert_equal({:has_m => true, :type => 'polygon', :srid => 3785}, col.limit)
  end

  #DEPRECATED
  def test_create_geometry_using_limit
    col = get_column_definition('region')
    assert_equal(RGeo::Feature::Polygon, col.geometric_type)
    assert_not col.geographic?
    assert_not col.has_z
    assert col.has_m
    assert_equal(3785, col.srid)
    #TODO REMOVE
    assert_equal({:has_m => true, :type => 'polygon', :srid => 3785}, col.limit)
  end

  private

  def klass
    City
  end

  def connection
    klass.connection
  end

  def columns
    klass.columns
  end

  def indexes
    connection.indexes(:cities)
  end

  def get_column_definition(name)
    columns.select{|x| x.name == name}.first
  end

  def get_table_index(name)
    indexes.select{|x| x.name == name}.first
  end
end
