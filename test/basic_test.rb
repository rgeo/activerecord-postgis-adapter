require 'test_helper'

class BasicTest < ActiveSupport::TestCase  # :nodoc:
  DATABASE_CONFIG_PATH = ::File.dirname(__FILE__)+'/database.yml'
  OVERRIDE_DATABASE_CONFIG_PATH = ::File.dirname(__FILE__)+'/database_local.yml'

  include RGeo::ActiveRecord::AdapterTestHelper

  define_test_methods do

    def populate_ar_class(content)
      klass = create_ar_class
      case content
      when :mercator_point
        klass.connection.create_table(:spatial_test) do |t|
          t.column 'latlon', :point, :srid => 3785
        end
      when :latlon_point_geographic
        klass.connection.create_table(:spatial_test) do |t|
          t.column 'latlon', :point, :srid => 4326, :geographic => true
        end
      end
      klass
    end

    def test_version
      refute_nil ::ActiveRecord::ConnectionAdapters::PostGISAdapter::VERSION
    end

    def test_postgis_available
      connection = create_ar_class.connection
      assert_equal 'PostGIS', connection.adapter_name
      refute_nil connection.postgis_lib_version
    end

    def test_set_and_get_point
      klass = populate_ar_class(:mercator_point)
      obj = klass.new
      assert_nil obj.latlon
      obj.latlon = @factory.point(1.0, 2.0)
      assert_equal @factory.point(1.0, 2.0), obj.latlon
      assert_equal 3785, obj.latlon.srid
    end

    def test_set_and_get_point_from_wkt
      klass = populate_ar_class(:mercator_point)
      obj = klass.new
      assert_nil obj.latlon
      obj.latlon = 'POINT(1 2)'
      assert_equal @factory.point(1.0, 2.0), obj.latlon
      assert_equal 3785, obj.latlon.srid
    end

    def test_save_and_load_point
      klass = populate_ar_class(:mercator_point)
      obj = klass.new
      obj.latlon = @factory.point(1.0, 2.0)
      obj.save!
      id = obj.id
      obj2 = klass.find(id)
      assert_equal @factory.point(1.0, 2.0), obj2.latlon
      assert_equal 3785, obj2.latlon.srid
      assert_equal true, ::RGeo::Geos.is_geos?(obj2.latlon)
    end

    def test_save_and_load_geographic_point
      klass = populate_ar_class(:latlon_point_geographic)
      obj = klass.new
      obj.latlon = @factory.point(1.0, 2.0)
      obj.save!
      id = obj.id
      obj2 = klass.find(id)
      assert_equal @geographic_factory.point(1.0, 2.0), obj2.latlon
      assert_equal 4326, obj2.latlon.srid
      assert_equal false, ::RGeo::Geos.is_geos?(obj2.latlon)
    end

    def test_save_and_load_point_from_wkt
      klass = populate_ar_class(:mercator_point)
      obj = klass.new
      obj.latlon = 'POINT(1 2)'
      obj.save!
      id = obj.id
      obj2 = klass.find(id)
      assert_equal @factory.point(1.0, 2.0), obj2.latlon
      assert_equal 3785, obj2.latlon.srid
    end

    def test_set_point_bad_wkt
      klass = populate_ar_class(:mercator_point)
      obj = klass.create(:latlon => 'POINT (x)')
      assert_nil obj.latlon
    end

    def test_set_point_wkt_wrong_type
      klass = populate_ar_class(:mercator_point)
      assert_raises(::ActiveRecord::StatementInvalid) do
        klass.create(:latlon => 'LINESTRING(1 2, 3 4, 5 6)')
      end
    end

    def test_custom_factory
      klass = create_ar_class
      klass.connection.create_table(:spatial_test) do |t|
        t.point(:latlon, :srid => 4326)
      end
      factory = ::RGeo::Geographic.simple_mercator_factory
      klass.class_eval do
        set_rgeo_factory_for_column(:latlon, factory)
      end
      object = klass.new
      object.latlon = 'POINT(-122 47)'
      assert_equal factory, object.latlon.factory
      object.save!
      assert_equal factory, object.latlon.factory
      rec2_ = klass.find(object.id)
      assert_equal factory, rec2_.latlon.factory
    end

    def test_readme_example
      klass = create_ar_class
      klass.connection.create_table(:spatial_test) do |t|
        t.column(:shape, :geometry)
        t.line_string(:path, :srid => 3785)
        t.point(:latlon, :geographic => true)
      end
      klass.connection.change_table(:spatial_test) do |t|
        t.index(:latlon, :spatial => true)
      end
      klass.class_eval do
        self.rgeo_factory_generator = ::RGeo::Geos.method(:factory)
        set_rgeo_factory_for_column(:latlon, ::RGeo::Geographic.spherical_factory)
      end
      object = klass.new
      object.latlon = 'POINT(-122 47)'
      loc_ = object.latlon
      assert_equal 47, loc_.latitude
      object.shape = loc_
      assert_equal true, ::RGeo::Geos.is_geos?(object.shape)
    end

    def test_point_to_json
      klass = populate_ar_class(:mercator_point)
      obj = klass.new
      assert_match(/"latlon":null/, obj.to_json)
      obj.latlon = @factory.point(1.0, 2.0)
      assert_match(/"latlon":"POINT\s\(1\.0\s2\.0\)"/, obj.to_json)
    end

    def test_custom_column
      klass = populate_ar_class(:mercator_point)
      rec = klass.new
      rec.latlon = 'POINT(0 0)'
      rec.save
      refute_nil klass.select("CURRENT_TIMESTAMP as ts").first.ts
    end

  end
end
