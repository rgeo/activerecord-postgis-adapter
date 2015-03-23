require "test_helper"

class SpatialFactoryStoreTest < ActiveSupport::TestCase
  def test_default
    store.clear
    assert RGeo::ActiveRecord::RGeoFactorySettings === store.default
  end

  def test_set_default
    store.clear
    default_factory = Object.new
    store.default = default_factory
    assert_equal default_factory, store.default
  end

  def test_register
    store.clear
    default_factory = Object.new
    store.default = default_factory

    point_factory = Object.new
    store.register point_factory, geo_type: "point", srid: 4326
    assert_equal point_factory, store.factory(geo_type: "point", srid: 4326)
    assert_equal 1, store.registry.size
    assert_equal point_factory, store.factory(geo_type: "point", srid: 4326)
    assert_equal 1, store.registry.size

    polygon_factory = Object.new
    store.register polygon_factory, geo_type: "polygon"
    assert_equal polygon_factory, store.factory(geo_type: "polygon")
    assert_equal 2, store.registry.size

    z_point_factory = Object.new
    store.register z_point_factory, geo_type: "point", has_z: true
    assert_equal z_point_factory, store.factory(geo_type: "point", has_z: true)

    assert_equal default_factory, store.factory(geo_type: "linestring")
  end

  private

  def store
    ActiveRecord::ConnectionAdapters::PostGISAdapter::SpatialFactoryStore.instance
  end
end
