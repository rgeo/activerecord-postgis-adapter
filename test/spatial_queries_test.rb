require 'test_helper'

class SpatialQueriesTest < ActiveSupport::TestCase  # :nodoc:

  DATABASE_CONFIG_PATH = ::File.dirname(__FILE__) + '/database.yml'

  include RGeo::ActiveRecord::AdapterTestHelper

  define_test_methods do

    def populate_ar_class(content)
      klass = create_ar_class
      case content
      when :mercator_point
        klass.connection.create_table(:spatial_test, force: true) do |t|
          t.column 'latlon', :point, srid: 3785
        end
      when :latlon_point_geographic
        klass.connection.create_table(:spatial_test, force: true) do |t|
          t.column 'latlon', :point, srid: 4326, geographic: true
        end
      when :path_linestring
        klass.connection.create_table(:spatial_test, force: true) do |t|
          t.column 'path', :line_string, srid: 3785
        end
      end
      klass
    end

    def test_query_point
      klass = populate_ar_class(:mercator_point)
      obj = klass.new
      obj.latlon = factory.point(1.0, 2.0)
      obj.save!
      id = obj.id
      obj2 = klass.where(latlon: factory.multi_point([factory.point(1.0, 2.0)])).first
      refute_nil(obj2)
      assert_equal(id, obj2.id)
      obj3 = klass.where(latlon: factory.point(2.0, 2.0)).first
      assert_nil(obj3)
    end

    def test_query_point_wkt
      klass = populate_ar_class(:mercator_point)
      obj = klass.new
      obj.latlon = factory.point(1.0, 2.0)
      obj.save!
      id = obj.id
      obj2 = klass.where(latlon: 'SRID=3785;POINT(1 2)').first
      refute_nil(obj2)
      assert_equal(id, obj2.id)
      obj3 = klass.where(latlon: 'SRID=3785;POINT(2 2)').first
      assert_nil(obj3)
    end

    def test_query_st_distance
      klass = populate_ar_class(:mercator_point)
      obj = klass.new
      obj.latlon = factory.point(1.0, 2.0)
      obj.save!
      id = obj.id
      obj2 = klass.where(klass.arel_table[:latlon].st_distance('SRID=3785;POINT(2 3)').lt(2)).first
      refute_nil(obj2)
      assert_equal(id, obj2.id)
      obj3 = klass.where(klass.arel_table[:latlon].st_distance('SRID=3785;POINT(2 3)').gt(2)).first
      assert_nil(obj3)
    end

    def test_query_st_distance_from_constant
      klass = populate_ar_class(:mercator_point)
      obj = klass.new
      obj.latlon = factory.point(1.0, 2.0)
      obj.save!
      id = obj.id
      obj2 = klass.where(::Arel.spatial('SRID=3785;POINT(2 3)').st_distance(klass.arel_table[:latlon]).lt(2)).first
      refute_nil(obj2)
      assert_equal(id, obj2.id)
      obj3 = klass.where(::Arel.spatial('SRID=3785;POINT(2 3)').st_distance(klass.arel_table[:latlon]).gt(2)).first
      assert_nil(obj3)
    end

    def test_query_st_length
      klass = populate_ar_class(:path_linestring)
      obj = klass.new
      obj.path = factory.line(factory.point(1.0, 2.0), factory.point(3.0, 2.0))
      obj.save!
      id = obj.id
      obj2 = klass.where(klass.arel_table[:path].st_length.eq(2)).first
      refute_nil(obj2)
      assert_equal(id, obj2.id)
      obj3 = klass.where(klass.arel_table[:path].st_length.gt(3)).first
      assert_nil(obj3)
    end

  end
end
