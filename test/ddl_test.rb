require 'test_helper'

class DDLTest < ActiveSupport::TestCase  # :nodoc:
  def test_spatial_column_options
    %i(
      geography
      geometry
      geometry_collection
      line_string
      multi_line_string
      multi_point
      multi_polygon
      st_point
      st_polygon
      ).each do |type|
      assert ActiveRecord::ConnectionAdapters::PostGISAdapter::MainAdapter.spatial_column_options(type), type
    end
  end

  def test_type_to_sql
    adapter = SpatialModel.connection
    assert_equal "geometry(point,4326)", adapter.type_to_sql(:geometry, "point,4326")
  end

  def test_create_simple_geometry
    klass.connection.create_table(:spatial_models, force: true) do |t|
      t.column 'latlon', :geometry
    end
    klass.reset_column_information
    assert_equal 1, count_geometry_columns
    col = klass.columns.last
    assert_equal RGeo::Feature::Geometry, col.geometric_type
    assert_equal true, col.has_spatial_constraints?
    assert_equal false, col.geographic?
    assert_equal 0, col.srid
    klass.connection.drop_table(:spatial_models)
    assert_equal 0, count_geometry_columns
  end

  def test_create_simple_geography
    klass.connection.create_table(:spatial_models, force: true) do |t|
      t.column 'latlon', :geometry, geographic: true
    end
    klass.reset_column_information
    col = klass.columns.last
    assert_equal RGeo::Feature::Geometry, col.geometric_type
    assert_equal true, col.has_spatial_constraints?
    assert_equal true, col.geographic?
    assert_equal 4326, col.srid
    assert_equal 0, count_geometry_columns
  end

  def test_create_point_geometry
    klass.connection.create_table(:spatial_models, force: true) do |t|
      t.column 'latlon', :st_point
    end
    klass.reset_column_information
    assert_equal RGeo::Feature::Point, klass.columns.last.geometric_type
  end

  def test_create_geometry_with_index
    klass.connection.create_table(:spatial_models, force: true) do |t|
      t.column 'latlon', :geometry
    end
    klass.connection.change_table(:spatial_models) do |t|
      t.index([:latlon], using: :gist)
    end
    klass.reset_column_information
    assert_equal :gist, klass.connection.indexes(:spatial_models).last.using
  end

  def test_add_geometry_column
    klass.connection.create_table(:spatial_models, force: true) do |t|
      t.column('latlon', :geometry)
    end
    klass.connection.change_table(:spatial_models) do |t|
      t.column('geom2', :st_point, srid: 4326)
      t.column('name', :string)
    end
    klass.reset_column_information
    assert_equal 2, count_geometry_columns
    columns = klass.columns
    assert_equal RGeo::Feature::Geometry, columns[-3].geometric_type
    assert_equal 0, columns[-3].srid
    assert_equal true, columns[-3].has_spatial_constraints?
    assert_equal RGeo::Feature::Point, columns[-2].geometric_type
    assert_equal 4326, columns[-2].srid
    assert_equal false, columns[-2].geographic?
    assert_equal true, columns[-2].has_spatial_constraints?
    assert_nil columns[-1].geometric_type
    assert_equal false, columns[-1].has_spatial_constraints?
  end

  def test_add_geometry_column_null_false
    klass.connection.create_table(:spatial_models, force: true) do |t|
      t.column('latlon_null', :geometry, null: false)
      t.column('latlon', :geometry)
    end
    klass.reset_column_information
    null_false_column = klass.columns[1]
    null_true_column = klass.columns[2]

    refute null_false_column.null, 'Column should be null: false'
    assert null_true_column.null, 'Column should be null: true'
  end

  def test_add_geography_column
    klass.connection.create_table(:spatial_models, force: true) do |t|
      t.column('latlon', :geometry)
    end
    klass.connection.change_table(:spatial_models) do |t|
      t.column('geom2', :st_point, srid: 4326, geographic: true)
      t.column('name', :string)
    end
    klass.reset_column_information
    assert_equal 1, count_geometry_columns
    cols_ = klass.columns
    assert_equal RGeo::Feature::Geometry, cols_[-3].geometric_type
    assert_equal 0, cols_[-3].srid
    assert_equal true, cols_[-3].has_spatial_constraints?
    assert_equal RGeo::Feature::Point, cols_[-2].geometric_type
    assert_equal 4326, cols_[-2].srid
    assert_equal true, cols_[-2].geographic?
    assert_equal true, cols_[-2].has_spatial_constraints?
    assert_nil cols_[-1].geometric_type
    assert_equal false, cols_[-1].has_spatial_constraints?
  end

  def test_drop_geometry_column
    klass.connection.create_table(:spatial_models, force: true) do |t|
      t.column('latlon', :geometry)
      t.column('geom2', :st_point, srid: 4326)
    end
    klass.connection.change_table(:spatial_models) do |t|
      t.remove('geom2')
    end
    klass.reset_column_information
    assert_equal 1, count_geometry_columns
    cols_ = klass.columns
    assert_equal RGeo::Feature::Geometry, cols_[-1].geometric_type
    assert_equal 'latlon', cols_[-1].name
    assert_equal 0, cols_[-1].srid
    assert_equal false, cols_[-1].geographic?
  end

  def test_drop_geography_column
    klass.connection.create_table(:spatial_models, force: true) do |t|
      t.column('latlon', :geometry)
      t.column('geom2', :st_point, srid: 4326, geographic: true)
      t.column('geom3', :st_point, srid: 4326)
    end
    klass.connection.change_table(:spatial_models) do |t|
      t.remove('geom2')
    end
    klass.reset_column_information
    assert_equal 2, count_geometry_columns
    columns = klass.columns
    assert_equal RGeo::Feature::Point, columns[-1].geometric_type
    assert_equal 'geom3', columns[-1].name
    assert_equal false, columns[-1].geographic?
    assert_equal RGeo::Feature::Geometry, columns[-2].geometric_type
    assert_equal 'latlon', columns[-2].name
    assert_equal false, columns[-2].geographic?
  end

  def test_create_simple_geometry_using_shortcut
    klass.connection.create_table(:spatial_models, force: true) do |t|
      t.geometry 'latlon'
    end
    klass.reset_column_information
    assert_equal 1, count_geometry_columns
    col = klass.columns.last
    assert_equal RGeo::Feature::Geometry, col.geometric_type
    assert_equal false, col.geographic?
    assert_equal 0, col.srid
    klass.connection.drop_table(:spatial_models)
    assert_equal 0, count_geometry_columns
  end

  def test_create_simple_geography_using_shortcut
    klass.connection.create_table(:spatial_models, force: true) do |t|
      t.geometry 'latlon', geographic: true
    end
    klass.reset_column_information
    col = klass.columns.last
    assert_equal RGeo::Feature::Geometry, col.geometric_type
    assert_equal true, col.geographic?
    assert_equal 4326, col.srid
    assert_equal 0, count_geometry_columns
  end

  def test_create_point_geometry_using_shortcut
    klass.connection.create_table(:spatial_models, force: true) do |t|
      t.st_point 'latlon'
    end
    klass.reset_column_information
    assert_equal RGeo::Feature::Point, klass.columns.last.geometric_type
  end

  def test_create_geometry_with_options
    klass.connection.create_table(:spatial_models, force: true) do |t|
      t.column 'region', :st_polygon, has_m: true, srid: 3785
    end
    klass.reset_column_information
    assert_equal 1, count_geometry_columns
    col = klass.columns.last
    assert_equal RGeo::Feature::Polygon, col.geometric_type
    assert_equal false, col.geographic?
    assert_equal false, col.has_z?
    assert_equal true, col.has_m?
    assert_equal 3785, col.srid
    assert_equal({ has_m: true, type: 'polygon', srid: 3785 }, col.limit)
    klass.connection.drop_table(:spatial_models)
    assert_equal 0, count_geometry_columns
  end

  def test_no_query_spatial_column_info
    klass.connection.create_table(:spatial_models, force: true) do |t|
      t.string 'name'
    end
    klass.reset_column_information
    # `all` queries column info from the database - it should not be called when klass.columns is called
    ActiveRecord::ConnectionAdapters::PostGISAdapter::SpatialColumnInfo.any_instance.expects(:all).never
    # first column is id, second is name
    refute klass.columns[1].spatial?
    assert_nil klass.columns[1].has_z
  end

  # Ensure that null contraints info is getting captured like the
  # normal adapter.
  def test_null_constraints
    klass.connection.create_table(:spatial_models, force: true) do |t|
      t.column 'nulls_allowed', :string, null: true
      t.column 'nulls_disallowed', :string, null: false
    end
    klass.reset_column_information
    assert_equal true, klass.columns[-2].null
    assert_equal false, klass.columns[-1].null
  end

  # Ensure column default value works like the Postgres adapter.
  def test_column_defaults
    klass.connection.create_table(:spatial_models, force: true) do |t|
      t.column 'sample_integer', :integer, default: -1
    end
    klass.reset_column_information
    assert_equal "-1", klass.columns.last.default
    assert_equal -1, klass.new.sample_integer
  end

  def test_column_types
    klass.connection.create_table(:spatial_models, force: true) do |t|
      t.column 'sample_integer', :integer
      t.column 'sample_string', :string
      t.column 'latlon', :st_point
    end
    klass.reset_column_information
    assert_equal :integer, klass.columns[-3].type
    assert_equal :string, klass.columns[-2].type
    assert_equal :geometry, klass.columns[-1].type
  end

  def test_array_columns
    klass.connection.create_table(:spatial_models, force: true) do |t|
      t.column 'sample_array', :string, array: true
      t.column 'sample_non_array', :string
    end
    klass.reset_column_information
    assert_equal true, klass.columns[-2].array
    assert_equal false, klass.columns[-1].array
  end

  private

  def klass
    SpatialModel
  end

  def count_geometry_columns
    klass.connection.select_value(geo_column_sql("geometry_columns", klass.table_name)).to_i
  end

  def geo_column_sql(postgis_view, table_name)
    "SELECT COUNT(*) FROM #{ postgis_view } WHERE f_table_name='#{ table_name }'"
  end

end
