require_relative 'helper'

class BasicTest < ActiveSupport::TestCase # :nodoc:
  def setup
    @factory = ::RGeo::Cartesian.preferred_factory(:srid => 3785)
    @geographic_factory = ::RGeo::Geographic.spherical_factory(:srid => 4326)
    @obj = City.new
  end

  def test_set_and_get_point
    assert_nil @obj.latlon3785
    @obj.latlon3785 = @factory.point(1.0, 2.0)
    assert_equal @factory.point(1.0, 2.0), @obj.latlon3785
    assert_equal 3785, @obj.latlon3785.srid
  end

  def test_set_and_get_point_from_wkt
    assert_nil @obj.latlon3785
    @obj.latlon3785 = 'POINT(1 2)'
    assert_equal @factory.point(1.0, 2.0), @obj.latlon3785
    assert_equal 3785, @obj.latlon3785.srid
  end

  def test_save_and_load_point
    @obj.latlon3785 = @factory.point(1.0, 2.0)
    @obj.save!
    id = @obj.id
    @obj2 = City.find(id)
    assert_equal @factory.point(1.0, 2.0), @obj2.latlon3785
    assert_equal 3785, @obj2.latlon3785.srid
    assert_equal true, ::RGeo::Geos.is_geos?(@obj2.latlon3785)
  end

  def test_save_and_load_geographic_point
    @obj.latlon4326 = @factory.point(1.0, 2.0)
    @obj.save!
    id = @obj.id
    @obj2 = City.find(id)
    assert_equal @geographic_factory.point(1.0, 2.0), @obj2.latlon4326
    assert_equal 4326, @obj2.latlon4326.srid
    assert_equal false, ::RGeo::Geos.is_geos?(@obj2.latlon4326)
  end

  def test_save_and_load_point_from_wkt
    @obj.latlon3785 = 'POINT(1 2)'
    @obj.save!
    id = @obj.id
    @obj2 = City.find(id)
    assert_equal @factory.point(1.0, 2.0), @obj2.latlon3785
    assert_equal 3785, @obj2.latlon3785.srid
  end

  def test_set_point_bad_wkt
    @obj = City.create(:latlon => 'POINT (x)')
    assert_nil @obj.latlon
  end

  def test_set_point_wkt_wrong_type
    assert_raises(::ActiveRecord::StatementInvalid) do
      City.create(:latlon => 'LINESTRING(1 2, 3 4, 5 6)')
    end
  end

  # def test_custom_factory
  #   simple_mercator_factory = RGeo::Geographic.simple_mercator_factory
  #   obj = SimpleCity.new
  #   obj.latlon4326 = 'POINT(-122 47)'
  #   assert_equal simple_mercator_factory, obj.latlon4326.factory
  #   obj.save!
  #   assert_equal simple_mercator_factory, obj.latlon4326.factory
  #   obj2 = SimpleCity.find(obj.id)
  #   assert_equal simple_mercator_factory, obj2.latlon4326.factory
  # end

  # def test_readme_example
  #   klass = create_ar_class
  #   klass.connection.create_table(:spatial_test) do |t_|
  #     t_.column(:shape, :geometry)
  #     t_.line_string(:path, :srid => 3785)
  #     t_.point(:latlon, :geographic => true)
  #   end
  #   klass.connection.change_table(:spatial_test) do |t_|
  #     t_.index(:latlon, :spatial => true)
  #   end
  #   klass.class_eval do
  #     self.rgeo_factory_generator = ::RGeo::Geos.method(:factory)
  #     set_rgeo_factory_for_column(:latlon, ::RGeo::Geographic.spherical_factory)
  #   end
  #   rec_ = klass.new
  #   rec_.latlon = 'POINT(-122 47)'
  #   loc_ = rec_.latlon
  #   assert_equal 47, loc_.latitude
  #   rec_.shape = loc_
  #   assert_equal true, ::RGeo::Geos.is_geos?(rec_.shape)
  # end
  #

  def test_point_to_json
    assert_match(/"latlon":null/, @obj.to_json)
    @obj.latlon = @factory.point(1.0, 2.0)
    assert_match(/"latlon":"POINT\s\(1\.0\s2\.0\)"/, @obj.to_json)
  end

  def test_custom_column
    @obj.latlon = 'POINT(0 0)'
    @obj.save
    refute_nil City.select("CURRENT_TIMESTAMP as ts").first.ts
  end

end
