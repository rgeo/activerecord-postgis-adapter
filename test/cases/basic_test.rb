require_relative 'test_helper'

class BasicTest < ActiveSupport::TestCase
  def setup
    @factory = RGeo::Cartesian.preferred_factory(:srid => 3785)
    @geographic_factory = RGeo::Geographic.spherical_factory(:srid => 4326)
    @obj = Geometry.new
  end

  def test_set_and_get_point
    assert_nil @obj.point_with_srid_3785
    @obj.point_with_srid_3785 = @factory.point(1.0, 2.0)
    assert_equal @factory.point(1.0, 2.0), @obj.point_with_srid_3785
    assert_equal 3785, @obj.point_with_srid_3785.srid
  end

  def test_set_and_get_point_from_wkt
    assert_nil @obj.point_with_srid_3785
    @obj.point_with_srid_3785 = 'POINT(1 2)'
    assert_equal @factory.point(1.0, 2.0), @obj.point_with_srid_3785
    assert_equal 3785, @obj.point_with_srid_3785.srid
  end

  def test_save_and_load_point
    @obj.point_with_srid_3785 = @factory.point(1.0, 2.0)
    @obj.save!
    id = @obj.id
    @obj2 = Geometry.find(id)
    assert_equal @factory.point(1.0, 2.0), @obj2.point_with_srid_3785
    assert_equal 3785, @obj2.point_with_srid_3785.srid
    assert_equal true, RGeo::Geos.is_geos?(@obj2.point_with_srid_3785)
  end

  def test_save_and_load_geographic_point
    @obj.geographic_point = @factory.point(1.0, 2.0)
    @obj.save!
    id = @obj.id
    @obj2 = Geometry.find(id)
    assert_equal @geographic_factory.point(1.0, 2.0), @obj2.geographic_point
    assert_equal 4326, @obj2.geographic_point.srid
    assert_equal false, RGeo::Geos.is_geos?(@obj2.geographic_point)
  end

  def test_set_point_bad_wkt
    @obj = Geometry.create(:point_with_srid_3785 => 'POINT (x)')
    assert_nil @obj.point_with_srid_3785
  end

  def test_set_point_wkt_wrong_type
    assert_raises(ActiveRecord::StatementInvalid) do
      Geometry.create(:point_with_srid_3785 => 'LINESTRING(1 2, 3 4, 5 6)')
    end
  end

  def test_point_to_json
    assert_match(/"point_with_srid_3785":null/, @obj.to_json)
    @obj.point_with_srid_3785 = @factory.point(1.0, 2.0)
    assert_match(/"point_with_srid_3785":"POINT\s\(1\.0\s2\.0\)"/, @obj.to_json)
  end

  def test_custom_column
    @obj.point_with_srid_3785 = 'POINT(0 0)'
    @obj.save
    refute_nil Geometry.select("CURRENT_TIMESTAMP as ts").first.ts
  end

end
