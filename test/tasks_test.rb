# frozen_string_literal: true

require "test_helper"

class TasksTest < ActiveSupport::TestCase
  def test_create_database_from_extension_in_public_schema
    drop_db_if_exists
    ActiveRecord::Tasks::DatabaseTasks.create(new_connection)
    refute_empty connection.select_values("SELECT * from public.spatial_ref_sys")
  end

  def test_create_database_from_extension_in_separate_schema
    drop_db_if_exists
    configuration = new_connection.merge("postgis_schema" => "postgis")
    ActiveRecord::Tasks::DatabaseTasks.create(configuration)
    refute_empty connection.select_values("SELECT * from postgis.spatial_ref_sys")
  end

  def test_empty_sql_dump
    setup_database_tasks
    ActiveRecord::Tasks::DatabaseTasks.structure_dump(new_connection, tmp_sql_filename)
    sql = File.read(tmp_sql_filename)
    assert(sql !~ /CREATE TABLE/)
  end

  def test_sql_dump
    setup_database_tasks
    connection.create_table(:spatial_test, force: true) do |t|
      t.st_point "latlon", geographic: true
      t.geometry "geo_col", srid: 4326
      t.column "poly", :multi_polygon, srid: 4326
    end
    ActiveRecord::Tasks::DatabaseTasks.structure_dump(new_connection, tmp_sql_filename)
    data = File.read(tmp_sql_filename)
    assert(data.index("latlon geography(Point,4326)"))
    assert(data.index("geo_col geometry(Geometry,4326)"))
    assert(data.index("poly geometry(MultiPolygon,4326)"))
  end

  def test_index_sql_dump
    setup_database_tasks
    connection.create_table(:spatial_test, force: true) do |t|
      t.st_point "latlon", geographic: true
      t.string "name"
    end
    connection.add_index :spatial_test, :latlon, using: :gist
    connection.add_index :spatial_test, :name, using: :btree
    ActiveRecord::Tasks::DatabaseTasks.structure_dump(new_connection, tmp_sql_filename)
    data = File.read(tmp_sql_filename)
    assert(data.index("latlon geography(Point,4326)"))
    assert data.index("CREATE INDEX index_spatial_test_on_latlon ON spatial_test USING gist (latlon);")
    assert data.index("CREATE INDEX index_spatial_test_on_name ON spatial_test USING btree (name);")
  end

  def test_empty_schema_dump
    setup_database_tasks
    File.open(tmp_sql_filename, "w:utf-8") do |file|
      ActiveRecord::SchemaDumper.dump(::ActiveRecord::Base.connection, file)
    end
    data = File.read(tmp_sql_filename)
    assert(data.index("ActiveRecord::Schema"))
  end

  def test_basic_geometry_schema_dump
    setup_database_tasks
    connection.create_table(:spatial_test, force: true) do |t|
      t.geometry "object1"
      t.spatial "object2", srid: connection.default_srid, type: "geometry"
    end
    File.open(tmp_sql_filename, "w:utf-8") do |file|
      ActiveRecord::SchemaDumper.dump(connection, file)
    end
    data = File.read(tmp_sql_filename)
    assert data.index("t.geometry \"object1\", limit: {:srid=>#{connection.default_srid}, :type=>\"geometry\"")
    assert data.index("t.geometry \"object2\", limit: {:srid=>#{connection.default_srid}, :type=>\"geometry\"")
  end

  def test_basic_geography_schema_dump
    setup_database_tasks
    connection.create_table(:spatial_test, force: true) do |t|
      t.st_point "latlon1", geographic: true
      t.spatial "latlon2", srid: 4326, type: "st_point", geographic: true
    end
    File.open(tmp_sql_filename, "w:utf-8") do |file|
      ActiveRecord::SchemaDumper.dump(connection, file)
    end
    data = File.read(tmp_sql_filename)
    assert data.index(%(t.geography "latlon1", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}))
    assert data.index(%(t.geography "latlon2", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}))
  end

  def test_index_schema_dump
    setup_database_tasks
    connection.create_table(:spatial_test, force: true) do |t|
      t.st_point "latlon", geographic: true
    end
    connection.add_index :spatial_test, :latlon, using: :gist
    File.open(tmp_sql_filename, "w:utf-8") do |file|
      ActiveRecord::SchemaDumper.dump(connection, file)
    end
    data = File.read(tmp_sql_filename)
    assert data.index(%(t.geography "latlon", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}))
    assert data.index(%(t.index ["latlon"], name: "index_spatial_test_on_latlon", using: :gist))
  end

  def test_add_index_with_no_options
    setup_database_tasks
    connection.create_table(:test, force: true) do |t|
      t.string "name"
    end
    connection.add_index :test, :name
    ActiveRecord::Tasks::DatabaseTasks.structure_dump(new_connection, tmp_sql_filename)
    data = File.read(tmp_sql_filename)
    assert data.index("CREATE INDEX index_test_on_name ON test USING btree (name);")
  end

  def test_add_index_via_references
    setup_database_tasks
    connection.create_table(:cats, force: true)
    connection.create_table(:dogs, force: true) do |t|
      t.references :cats, index: true
    end
    ActiveRecord::Tasks::DatabaseTasks.structure_dump(new_connection, tmp_sql_filename)
    data = File.read(tmp_sql_filename)
    assert data.index("CREATE INDEX index_dogs_on_cats_id ON dogs USING btree (cats_id);")
  end

  private

  def new_connection
    ActiveRecord::Base.test_connection_hash.merge("database" => "postgis_tasks_test")
  end
  
  def connection
    ActiveRecord::Base.connection
  end

  def tmp_sql_filename
    File.expand_path("../tmp/tmp.sql", File.dirname(__FILE__))
  end

  def setup_database_tasks
    FileUtils.rm_f(tmp_sql_filename)
    FileUtils.mkdir_p(File.dirname(tmp_sql_filename))
    drop_db_if_exists
    ActiveRecord::ConnectionAdapters::PostGIS::PostGISDatabaseTasks.new(new_connection).create
  rescue ActiveRecord::Tasks::DatabaseAlreadyExists
    # ignore
  end

  def drop_db_if_exists
    ActiveRecord::ConnectionAdapters::PostGIS::PostGISDatabaseTasks.new(new_connection).drop
  rescue ActiveRecord::Tasks::DatabaseAlreadyExists
    # ignore
  end
end
