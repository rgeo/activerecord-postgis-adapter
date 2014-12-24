require_relative 'test_helper'

class SpatialQueriesTest < ActiveSupport::TestCase
  def setup
    @factory = ::RGeo::Cartesian.preferred_factory(:srid => 3785)
    @geographic_factory = ::RGeo::Geographic.spherical_factory(:srid => 4326)
    Geometry.delete_all
    @obj = Geometry.new
  end

  def test_query_point
    @obj.point_with_srid_3785 = @factory.point(1.0, 2.0)
    @obj.save!
    id = @obj.id
    @obj2 = Geometry.where(:point_with_srid_3785 => @factory.multi_point([@factory.point(1.0, 2.0)])).first
    refute_nil(@obj2)
    assert_equal(id, @obj2.id)
    @obj3 = Geometry.where(:point_with_srid_3785 => @factory.point(2.0, 2.0)).first
    assert_nil(@obj3)
  end

  def test_query_st_distance
    @obj.point_with_srid_3785 = @factory.point(1.0, 2.0)
    @obj.save!
    id = @obj.id
    @obj2 = Geometry.where(Geometry.arel_table[:point_with_srid_3785].st_distance('SRID=3785;POINT(2 3)').lt(2)).first
    refute_nil(@obj2)
    assert_equal(id, @obj2.id)
    @obj3 = Geometry.where(Geometry.arel_table[:point_with_srid_3785].st_distance('SRID=3785;POINT(2 3)').gt(2)).first
    assert_nil(@obj3)
  end

  def test_query_st_distance_from_constant
    @obj.point_with_srid_3785 = @factory.point(1.0, 2.0)
    @obj.save!
    id = @obj.id
    @obj2 = Geometry.where(Arel.spatial('SRID=3785;POINT(2 3)').st_distance(Geometry.arel_table[:point_with_srid_3785]).lt(2)).first
    refute_nil(@obj2)
    assert_equal(id, @obj2.id)
    @obj3 = Geometry.where(Arel.spatial('SRID=3785;POINT(2 3)').st_distance(Geometry.arel_table[:point_with_srid_3785]).gt(2)).first
    assert_nil(@obj3)
  end

  def test_query_st_length
    @obj.linestring_with_srid = @factory.line(@factory.point(1.0, 2.0), @factory.point(3.0, 2.0))
    @obj.save!
    id = @obj.id
    @obj2 = Geometry.where(Geometry.arel_table[:linestring_with_srid].st_length.eq(2)).first
    refute_nil(@obj2)
    assert_equal(id, @obj2.id)
    @obj3 = Geometry.where(Geometry.arel_table[:linestring_with_srid].st_length.gt(3)).first
    assert_nil(@obj3)
  end
end
