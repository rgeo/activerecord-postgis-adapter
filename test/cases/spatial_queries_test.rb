require_relative 'helper'

class SpatialQueriesTest < ActiveSupport::TestCase # :nodoc:
  def setup
    @factory = ::RGeo::Cartesian.preferred_factory(:srid => 3785)
    @geographic_factory = ::RGeo::Geographic.spherical_factory(:srid => 4326)
    City.delete_all
    @obj = City.new
  end

  def test_query_point
    @obj.latlon3785 = @factory.point(1.0, 2.0)
    @obj.save!
    id = @obj.id
    @obj2 = City.where(:latlon3785 => @factory.multi_point([@factory.point(1.0, 2.0)])).first
    refute_nil(@obj2)
    assert_equal(id, @obj2.id)
    @obj3 = City.where(:latlon3785 => @factory.point(2.0, 2.0)).first
    assert_nil(@obj3)
  end

  def test_query_point_wkt
    @obj.latlon3785 = @factory.point(1.0, 2.0)
    @obj.save!
    id = @obj.id
    @obj2 = City.where(:latlon3785 => 'SRID=3785;POINT(1 2)').first
    refute_nil(@obj2)
    assert_equal(id, @obj2.id)
    @obj3 = City.where(:latlon3785 => 'SRID=3785;POINT(2 2)').first
    assert_nil(@obj3)
  end

  def test_query_st_distance
    @obj.latlon3785 = @factory.point(1.0, 2.0)
    @obj.save!
    id = @obj.id
    @obj2 = City.where(City.arel_table[:latlon3785].st_distance('SRID=3785;POINT(2 3)').lt(2)).first
    refute_nil(@obj2)
    assert_equal(id, @obj2.id)
    @obj3 = City.where(City.arel_table[:latlon3785].st_distance('SRID=3785;POINT(2 3)').gt(2)).first
    assert_nil(@obj3)
  end

  def test_query_st_distance_from_constant
    @obj.latlon3785 = @factory.point(1.0, 2.0)
    @obj.save!
    id = @obj.id
    @obj2 = City.where(Arel.spatial('SRID=3785;POINT(2 3)').st_distance(City.arel_table[:latlon3785]).lt(2)).first
    refute_nil(@obj2)
    assert_equal(id, @obj2.id)
    @obj3 = City.where(Arel.spatial('SRID=3785;POINT(2 3)').st_distance(City.arel_table[:latlon3785]).gt(2)).first
    assert_nil(@obj3)
  end

  def test_query_st_length
    @obj.path = @factory.line(@factory.point(1.0, 2.0), @factory.point(3.0, 2.0))
    @obj.save!
    id = @obj.id
    @obj2 = City.where(City.arel_table[:path].st_length.eq(2)).first
    refute_nil(@obj2)
    assert_equal(id, @obj2.id)
    @obj3 = City.where(City.arel_table[:path].st_length.gt(3)).first
    assert_nil(@obj3)
  end

end