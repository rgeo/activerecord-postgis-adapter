# frozen_string_literal: true

require "test_helper"

class Foo < ActiveRecord::Base
  establish_test_connection
  has_one :spatial_foo
  attribute :bar, :string, array: true
  attribute :baz, :string, range: true
end

class SpatialFoo < ActiveRecord::Base
  establish_test_connection
  attribute :point, :st_point, srid: 3857
  attribute :pointz, :st_point, has_z: true, srid: 3509
  attribute :pointm, :st_point, has_m: true, srid: 3509
  attribute :polygon, :st_polygon, srid: 3857
  attribute :path, :line_string, srid: 3857
  attribute :geo_path, :line_string, geographic: true, srid: 4326
end

class InvalidAttribute < ActiveRecord::Base
  establish_test_connection
end

class AttributesTest < ActiveSupport::TestCase
  def setup
    reset_spatial_store
    create_foo
    create_spatial_foo
    create_invalid_attributes
  end

  def test_postgresql_attributes_registered
    assert Foo.attribute_names.include?("bar")
    assert Foo.attribute_names.include?("baz")

    data = Foo.new
    data.bar = %w[a b c]
    data.baz = "1".."3"

    assert_equal data.bar, %w[a b c]
    assert_equal data.baz, "1".."3"
  end

  def test_invalid_attribute
    assert_raises(ArgumentError) do
      InvalidAttribute.attribute(:attr, :invalid_attr)
      InvalidAttribute.new
    end
  end

  def test_spatial_attributes
    data = SpatialFoo.new
    data.point = "POINT(0 0)"
    data.pointz = "POINT(0 0 1)"
    data.pointm = "POINT(0 0 2)"
    data.polygon = "POLYGON((0 0, 0 1, 1 1, 1 0, 0 0))"
    data.path = "LINESTRING(0 0, 0 1, 1 1, 1 0, 0 0)"
    data.geo_path = "LINESTRING(-75.165222 39.952583,-73.561668 45.508888)"

    assert_equal 3857, data.point.srid
    assert_equal 0, data.point.x
    assert_equal 0, data.point.y

    assert_equal 3509, data.pointz.srid
    assert_equal 1, data.pointz.z

    assert_equal 3509, data.pointm.srid
    assert_equal 2, data.pointm.m

    assert_equal 3857, data.polygon.srid
    assert_equal 3857, data.path.srid
    assert_equal data.path, data.polygon.exterior_ring

    assert_equal 4326, data.geo_path.srid
    assert_equal RGeo::Geographic::Factory, data.geo_path.factory.class
  end

  def test_joined_spatial_attribute
    # TODO: The attributes that will be joined have to be defined on the
    # model we make the query with. Ideally, it would "just work" but
    # at least this workaround makes joining functional.
    Foo.attribute :geo_point, :st_point, srid: 4326, geographic: true
    Foo.attribute :cart_point, :st_point, srid: 3509

    foo = Foo.create
    SpatialFoo.create(foo_id: foo.id, geo_point: "POINT(10 10)", cart_point: "POINT(2 2)")

    # query foo and join child spatial foo on it
    foo = Foo.joins(:spatial_foo).select("foos.id, spatial_foos.geo_point, spatial_foos.cart_point").first
    assert_equal 4326, foo.geo_point.srid
    assert_equal 3509, foo.cart_point.srid
    assert_equal foo.geo_point, SpatialFoo.first.geo_point
    assert_equal foo.cart_point, SpatialFoo.first.cart_point
  end

  private

  def create_foo
    Foo.connection.create_table :foos, force: true do |t|
    end
  end

  def create_spatial_foo
    SpatialFoo.connection.create_table :spatial_foos, force: true do |t|
      t.references :foo
      t.st_point :geo_point, geographic: true, srid: 4326
      t.st_point :cart_point, srid: 3509
    end
  end

  def create_invalid_attributes
    InvalidAttribute.connection.create_table :invalid_attributes, force: true do |t|
    end
  end
end
