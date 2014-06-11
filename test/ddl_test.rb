require 'test_helper'

class DDLTest < ActiveSupport::TestCase  # :nodoc:
  DATABASE_CONFIG_PATH = ::File.dirname(__FILE__) + '/database.yml'
  OVERRIDE_DATABASE_CONFIG_PATH = ::File.dirname(__FILE__) + '/database_local.yml'

  include RGeo::ActiveRecord::AdapterTestHelper

  define_test_methods do
    def test_create_simple_geometry
      klass = create_ar_class
      klass.connection.create_table(:spatial_test) do |t|
        t.column 'latlon', :geometry
      end
      assert_equal(1, klass.connection.select_value(geometry_column_count_query).to_i)
      col = klass.columns.last
      assert_equal(::RGeo::Feature::Geometry, col.geometric_type)
      assert_equal(true, col.has_spatial_constraints?)
      assert_equal(false, col.geographic?)
      assert_equal(0, col.srid)
      assert(klass.cached_attributes.include?('latlon'))
      klass.connection.drop_table(:spatial_test)
      assert_equal(0, klass.connection.select_value(geometry_column_count_query).to_i)
    end

    def test_create_simple_geography
      klass = create_ar_class
      klass.connection.create_table(:spatial_test) do |t|
        t.column 'latlon', :geometry, :geographic => true
      end
      col = klass.columns.last
      assert_equal(::RGeo::Feature::Geometry, col.geometric_type)
      assert_equal(true, col.has_spatial_constraints?)
      assert_equal(true, col.geographic?)
      assert_equal(4326, col.srid)
      assert(klass.cached_attributes.include?('latlon'))
      assert_equal(0, klass.connection.select_value(geometry_column_count_query).to_i)
    end

    def test_create_point_geometry
      klass = create_ar_class
      klass.connection.create_table(:spatial_test) do |t|
        t.column 'latlon', :point
      end
      assert_equal(::RGeo::Feature::Point, klass.columns.last.geometric_type)
      assert(klass.cached_attributes.include?('latlon'))
    end

    def test_create_geometry_with_index
      klass = create_ar_class
      klass.connection.create_table(:spatial_test) do |t|
        t.column 'latlon', :geometry
      end
      klass.connection.change_table(:spatial_test) do |t|
        t.index([:latlon], :spatial => true)
      end
      assert(klass.connection.indexes(:spatial_test).last.spatial)
    end

    def test_add_geometry_column
      klass = create_ar_class
      klass.connection.create_table(:spatial_test) do |t|
        t.column('latlon', :geometry)
      end
      klass.connection.change_table(:spatial_test) do |t|
        t.column('geom2', :point, :srid => 4326)
        t.column('name', :string)
      end
      assert_equal(2, klass.connection.select_value(geometry_column_count_query).to_i)
      cols_ = klass.columns
      assert_equal(::RGeo::Feature::Geometry, cols_[-3].geometric_type)
      assert_equal(0, cols_[-3].srid)
      assert_equal(true, cols_[-3].has_spatial_constraints?)
      assert_equal(::RGeo::Feature::Point, cols_[-2].geometric_type)
      assert_equal(4326, cols_[-2].srid)
      assert_equal(false, cols_[-2].geographic?)
      assert_equal(true, cols_[-2].has_spatial_constraints?)
      assert_nil(cols_[-1].geometric_type)
      assert_equal(false, cols_[-1].has_spatial_constraints?)
    end

    def test_add_geometry_column_null_false
      klass = create_ar_class
      klass.connection.create_table(:spatial_test) do |t|
        t.column('latlon', :geometry, null: false)
      end
      geometry_column = klass.columns.first

      refute(geometry_column.null, 'Column should be null: false')
    end

    def test_add_geography_column
      klass = create_ar_class
      klass.connection.create_table(:spatial_test) do |t|
        t.column('latlon', :geometry)
      end
      klass.connection.change_table(:spatial_test) do |t|
        t.column('geom2', :point, :srid => 4326, :geographic => true)
        t.column('name', :string)
      end
      assert_equal(1, klass.connection.select_value(geometry_column_count_query).to_i)
      cols_ = klass.columns
      assert_equal(::RGeo::Feature::Geometry, cols_[-3].geometric_type)
      assert_equal(0, cols_[-3].srid)
      assert_equal(true, cols_[-3].has_spatial_constraints?)
      assert_equal(::RGeo::Feature::Point, cols_[-2].geometric_type)
      assert_equal(4326, cols_[-2].srid)
      assert_equal(true, cols_[-2].geographic?)
      assert_equal(true, cols_[-2].has_spatial_constraints?)
      assert_nil(cols_[-1].geometric_type)
      assert_equal(false, cols_[-1].has_spatial_constraints?)
    end

    def test_drop_geometry_column
      klass = create_ar_class
      klass.connection.create_table(:spatial_test) do |t|
        t.column('latlon', :geometry)
        t.column('geom2', :point, :srid => 4326)
      end
      klass.connection.change_table(:spatial_test) do |t|
        t.remove('geom2')
      end
      assert_equal(1, klass.connection.select_value(geometry_column_count_query).to_i)
      cols_ = klass.columns
      assert_equal(::RGeo::Feature::Geometry, cols_[-1].geometric_type)
      assert_equal('latlon', cols_[-1].name)
      assert_equal(0, cols_[-1].srid)
      assert_equal(false, cols_[-1].geographic?)
    end

    def test_drop_geography_column
      klass = create_ar_class
      klass.connection.create_table(:spatial_test) do |t|
        t.column('latlon', :geometry)
        t.column('geom2', :point, :srid => 4326, :geographic => true)
        t.column('geom3', :point, :srid => 4326)
      end
      klass.connection.change_table(:spatial_test) do |t|
        t.remove('geom2')
      end
      assert_equal(2, klass.connection.select_value(geometry_column_count_query).to_i)
      cols_ = klass.columns
      assert_equal(::RGeo::Feature::Point, cols_[-1].geometric_type)
      assert_equal('geom3', cols_[-1].name)
      assert_equal(false, cols_[-1].geographic?)
      assert_equal(::RGeo::Feature::Geometry, cols_[-2].geometric_type)
      assert_equal('latlon', cols_[-2].name)
      assert_equal(false, cols_[-2].geographic?)
    end

    def test_create_simple_geometry_using_shortcut
      klass = create_ar_class
      klass.connection.create_table(:spatial_test) do |t|
        t.geometry 'latlon'
      end
      assert_equal(1, klass.connection.select_value(geometry_column_count_query).to_i)
      col = klass.columns.last
      assert_equal(::RGeo::Feature::Geometry, col.geometric_type)
      assert_equal(false, col.geographic?)
      assert_equal(0, col.srid)
      assert(klass.cached_attributes.include?('latlon'))
      klass.connection.drop_table(:spatial_test)
      assert_equal(0, klass.connection.select_value(geometry_column_count_query).to_i)
    end

    def test_create_simple_geography_using_shortcut
      klass = create_ar_class
      klass.connection.create_table(:spatial_test) do |t|
        t.geometry 'latlon', :geographic => true
      end
      col = klass.columns.last
      assert_equal(::RGeo::Feature::Geometry, col.geometric_type)
      assert_equal(true, col.geographic?)
      assert_equal(4326, col.srid)
      assert(klass.cached_attributes.include?('latlon'))
      assert_equal(0, klass.connection.select_value(geometry_column_count_query).to_i)
    end

    def test_create_point_geometry_using_shortcut
      klass = create_ar_class
      klass.connection.create_table(:spatial_test) do |t|
        t.point 'latlon'
      end
      assert_equal(::RGeo::Feature::Point, klass.columns.last.geometric_type)
      assert(klass.cached_attributes.include?('latlon'))
    end

    def test_create_geometry_with_options
      klass = create_ar_class
      klass.connection.create_table(:spatial_test) do |t|
        t.column 'region', :polygon, :has_m => true, :srid => 3785
      end
      assert_equal(1, klass.connection.select_value(geometry_column_count_query).to_i)
      col = klass.columns.last
      assert_equal(::RGeo::Feature::Polygon, col.geometric_type)
      assert_equal(false, col.geographic?)
      assert_equal(false, col.has_z?)
      assert_equal(true, col.has_m?)
      assert_equal(3785, col.srid)
      assert_equal({:has_m => true, :type => 'polygon', :srid => 3785}, col.limit)
      assert(klass.cached_attributes.include?('region'))
      klass.connection.drop_table(:spatial_test)
      assert_equal(0, klass.connection.select_value(geometry_column_count_query).to_i)
    end

    def test_create_geometry_using_limit
      klass = create_ar_class
      klass.connection.create_table(:spatial_test) do |t|
        t.spatial 'region', :limit => {:has_m => true, :srid => 3785, :type => :polygon}
      end
      assert_equal(1, klass.connection.select_value(geometry_column_count_query).to_i)
      col = klass.columns.last
      assert_equal(::RGeo::Feature::Polygon, col.geometric_type)
      assert_equal(false, col.geographic?)
      assert_equal(false, col.has_z)
      assert_equal(true, col.has_m)
      assert_equal(3785, col.srid)
      assert_equal({:has_m => true, :type => 'polygon', :srid => 3785}, col.limit)
      assert(klass.cached_attributes.include?('region'))
      klass.connection.drop_table(:spatial_test)
      assert_equal(0, klass.connection.select_value(geometry_column_count_query).to_i)
    end

    def test_caches_spatial_column_info
      klass = create_ar_class
      klass.connection.create_table(:spatial_test, force: true) do |t|
        t.point 'latlon'
        t.point 'other'
      end
      ::ActiveRecord::ConnectionAdapters::PostGISAdapter::SpatialColumnInfo.any_instance.expects(:all).once.returns({})
      klass.columns
      klass.columns
    end

    def test_no_query_spatial_column_info
      klass = create_ar_class
      klass.connection.create_table(:spatial_test, force: true) do |t|
        t.string 'name'
      end
      # `all` queries column info from the database - it should not be called when klass.columns is called
      ::ActiveRecord::ConnectionAdapters::PostGISAdapter::SpatialColumnInfo.any_instance.expects(:all).never
      # first column is id, second is name
      refute klass.columns[1].spatial?
      assert_nil klass.columns[1].has_z
    end

    private

    def geometry_column_count_query
      "SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'"
    end
  end

end
