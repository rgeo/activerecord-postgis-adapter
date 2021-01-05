# frozen_string_literal: true

require "test_helper"

class SpatialQueriesTest < ActiveSupport::TestCase
  def test_query_point
    create_model
    obj = SpatialModel.create!(latlon: factory.point(1, 2))
    id = obj.id
    assert_empty SpatialModel.where(latlon: factory.point(2, 2))
    obj1 = SpatialModel.find_by(latlon: factory.point(1, 2))
    refute_nil(obj1)
    assert_equal id, obj1.id
  end

  def test_query_multi_point
    create_model
    obj = SpatialModel.create!(points: factory.multi_point([factory.point(1, 2)]))
    id = obj.id
    obj2 = SpatialModel.find_by(points: factory.multi_point([factory.point(1, 2)]))
    refute_nil(obj2)
    assert_equal(id, obj2.id)
  end

  def test_query_point_wkt
    create_model
    obj = SpatialModel.create!(latlon: factory.point(1, 2))
    id = obj.id
    obj2 = SpatialModel.find_by(latlon: "SRID=3785;POINT(1 2)")
    refute_nil(obj2)
    assert_equal(id, obj2.id)
    obj3 = SpatialModel.find_by(latlon: "SRID=3785;POINT(2 2)")
    assert_nil(obj3)
  end

  def test_query_st_distance
    create_model
    obj = SpatialModel.create!(latlon: factory.point(1, 2))
    id = obj.id
    obj2 = SpatialModel.find_by(SpatialModel.arel_table[:latlon].st_distance("SRID=3785;POINT(2 3)").lt(2))
    refute_nil(obj2)
    assert_equal(id, obj2.id)
    obj3 = SpatialModel.find_by(SpatialModel.arel_table[:latlon].st_distance("SRID=3785;POINT(2 3)").gt(2))
    assert_nil(obj3)
  end

  def test_query_st_distance_from_constant
    create_model
    obj = SpatialModel.create!(latlon: factory.point(1, 2))
    id = obj.id

    query_point = parser.parse("SRID=3785;POINT(2 3)")
    obj2 = SpatialModel.find_by(Arel.spatial(query_point).st_distance(SpatialModel.arel_table[:latlon]).lt(2))
    refute_nil(obj2)
    assert_equal(id, obj2.id)
    obj3 = SpatialModel.find_by(Arel.spatial(query_point).st_distance(SpatialModel.arel_table[:latlon]).gt(2))
    assert_nil(obj3)
  end

  def test_query_st_length
    create_model
    obj = SpatialModel.new
    obj.path = factory.line(factory.point(1.0, 2.0), factory.point(3.0, 2.0))
    obj.save!
    id = obj.id
    obj2 = SpatialModel.find_by(SpatialModel.arel_table[:path].st_length.eq(2))
    refute_nil(obj2)
    assert_equal(id, obj2.id)
    obj3 = SpatialModel.find_by(SpatialModel.arel_table[:path].st_length.gt(3))
    assert_nil(obj3)
  end

  def test_query_rgeo_feature_node
    create_model
    obj = SpatialModel.new
    obj.path = factory.line_string([factory.point(1.0, 2.0),
                                    factory.point(2.0, 2.0), factory.point(3.0, 2.0)])
    obj.save!
    id = obj.id

    query_point = factory.point(2.0, 2.0)
    obj2 = SpatialModel.find_by(SpatialModel.arel_table[:path].st_contains(query_point))
    assert_equal(id, obj2.id)

    query_point = factory.point(0.0, 2.0)
    obj3 = SpatialModel.find_by(SpatialModel.arel_table[:path].st_contains(query_point))
    assert_nil(obj3)
  end

  def test_query_rgeo_bbox_node
    create_model
    obj = SpatialModel.new
    obj.latlon = factory.point(1, 2)
    obj.save!
    id = obj.id

    pt1 = factory.point(-1, -1)
    pt2 = factory.point(4, 4)
    bbox = RGeo::Cartesian::BoundingBox.create_from_points(pt1, pt2)
    obj2 = SpatialModel.find_by(SpatialModel.arel_table[:latlon].st_within(bbox))
    assert_equal(id, obj2.id)
  end

  def test_ewkt_parser_query
    create_model
    obj = SpatialModel.create!(latlon: factory.point(1, 2))
    id = obj.id

    query_point = parser.parse("SRID=3785;POINT(2 3)")
    obj2 = SpatialModel.find_by(Arel.spatial(query_point).st_distance(SpatialModel.arel_table[:latlon]).lt(2))
    refute_nil(obj2)
    assert_equal(id, obj2.id)
    obj3 = SpatialModel.find_by(Arel.spatial(query_point).st_distance(SpatialModel.arel_table[:latlon]).gt(2))
    assert_nil(obj3)
  end

  private

  def create_model
    SpatialModel.connection.create_table(:spatial_models, force: true) do |t|
      t.column "latlon", :st_point, srid: 3785
      t.column "points", :multi_point, srid: 3785
      t.column "path", :line_string, srid: 3785
    end
    SpatialModel.reset_column_information
  end

  def parser
    RGeo::WKRep::WKTParser.new(nil, support_ewkt: true)
  end
end
