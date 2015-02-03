require 'test_helper'
require 'active_record/schema_dumper'

class TasksTest < ActiveSupport::TestCase  # :nodoc:
  DATABASE_CONFIG_PATH = ::File.dirname(__FILE__) + '/database.yml'

  class << self
    def before_open_database(args)
      @new_database_config = args[:config].merge('database' => 'postgis_adapter_test2')
      @new_database_config.stringify_keys!
    end
    attr_reader :new_database_config
  end

  include RGeo::ActiveRecord::AdapterTestHelper

  def cleanup_tables
    ::ActiveRecord::Base.remove_connection
    ::ActiveRecord::Base.clear_active_connections!
    TasksTest::DEFAULT_AR_CLASS.connection.execute("DROP DATABASE IF EXISTS \"postgis_adapter_test2\"")
  end

  define_test_methods do
    def test_create_database_from_extension_in_public_schema
      ActiveRecord::Tasks::DatabaseTasks.create(TasksTest.new_database_config)
      refute_empty connection.select_values("SELECT * from public.spatial_ref_sys")
    end

    def test_create_database_from_extension_in_separate_schema
      configuration = TasksTest.new_database_config.merge('postgis_schema' => 'postgis')
      ActiveRecord::Tasks::DatabaseTasks.create(configuration)
      refute_empty connection.select_values("SELECT * from postgis.spatial_ref_sys")
    end

    def test_empty_sql_dump
      setup_database_tasks
      ActiveRecord::Tasks::DatabaseTasks.structure_dump(TasksTest.new_database_config, tmp_sql_filename)
      sql = File.read(tmp_sql_filename)
      assert(sql !~ /CREATE TABLE/)
    end

    def test_basic_geography_sql_dump
      setup_database_tasks
      connection.create_table(:spatial_test, force: true) do |t|
        t.st_point "latlon", geographic: true
      end
      ActiveRecord::Tasks::DatabaseTasks.structure_dump(TasksTest.new_database_config, tmp_sql_filename)
      data = File.read(tmp_sql_filename)
      assert(data.index('latlon geography(Point,4326)'))
    end

    def test_index_sql_dump
      setup_database_tasks
      connection.create_table(:spatial_test, force: true) do |t|
        t.st_point "latlon", geographic: true
        t.string "name"
      end
      connection.add_index :spatial_test, :latlon, spatial: true
      connection.add_index :spatial_test, :name, using: :btree
      ActiveRecord::Tasks::DatabaseTasks.structure_dump(TasksTest.new_database_config, tmp_sql_filename)
      data = File.read(tmp_sql_filename)
      assert(data.index('latlon geography(Point,4326)'))
      assert data.index('CREATE INDEX index_spatial_test_on_latlon ON spatial_test USING gist (latlon);')
      assert data.index('CREATE INDEX index_spatial_test_on_name ON spatial_test USING btree (name);')
    end

    def test_empty_schema_dump
      setup_database_tasks
      File.open(tmp_sql_filename, "w:utf-8") do |file|
        ActiveRecord::SchemaDumper.dump(::ActiveRecord::Base.connection, file)
      end
      data = File.read(tmp_sql_filename)
      assert(data.index('ActiveRecord::Schema'))
    end

    def test_basic_geometry_schema_dump
      setup_database_tasks
      connection.create_table(:spatial_test, force: true) do |t|
        t.geometry 'object1'
        t.spatial "object2", srid: connection.default_srid, type: "geometry"
      end
      File.open(tmp_sql_filename, "w:utf-8") do |file|
        ActiveRecord::SchemaDumper.dump(connection, file)
      end
      data = File.read(tmp_sql_filename)
      assert(data.index("t.geometry \"object1\", limit: {:srid=>#{connection.default_srid}, :type=>\"geometry\""))
      assert(data.index("t.geometry \"object2\", limit: {:srid=>#{connection.default_srid}, :type=>\"geometry\""))
    end

    def test_basic_geography_schema_dump
      setup_database_tasks
      connection.create_table(:spatial_test, force: true) do |t|
        t.st_point "latlon1", geographic: true
        t.spatial "latlon2", srid: 4326, type: "point", geographic: true
      end
      File.open(tmp_sql_filename, "w:utf-8") do |file|
        ActiveRecord::SchemaDumper.dump(connection, file)
      end
      data = File.read(tmp_sql_filename)
      assert(data.index('t.geography "latlon1", limit: {:srid=>4326, :type=>"point", :geographic=>true}'))
      assert(data.index('t.point     "latlon2"'))
    end

    def test_index_schema_dump
      setup_database_tasks
      connection.create_table(:spatial_test, force: true) do |t|
        t.st_point "latlon", geographic: true
      end
      connection.add_index :spatial_test, :latlon, spatial: true
      File.open(tmp_sql_filename, "w:utf-8") do |file|
        ActiveRecord::SchemaDumper.dump(connection, file)
      end
      data = File.read(tmp_sql_filename)
      assert data.index('t.geography "latlon", limit: {:srid=>4326, :type=>"point", :geographic=>true}')
      assert data.index('add_index "spatial_test", ["latlon"], name: "index_spatial_test_on_latlon", spatial: true')
    end

    def test_add_index_with_nil_options
      setup_database_tasks
      connection.create_table(:test, force: true) do |t|
        t.string "name"
      end
      connection.add_index :test, :name, nil
      ActiveRecord::Tasks::DatabaseTasks.structure_dump(TasksTest.new_database_config, tmp_sql_filename)
      data = File.read(tmp_sql_filename)
      assert data.index('CREATE INDEX index_test_on_name ON test USING btree (name);')
    end

    def test_add_index_via_references
      setup_database_tasks
      connection.create_table(:cats, force: true)
      connection.create_table(:dogs, force: true) do |t|
        t.references :cats, index: true
      end
      ActiveRecord::Tasks::DatabaseTasks.structure_dump(TasksTest.new_database_config, tmp_sql_filename)
      data = File.read(tmp_sql_filename)
      assert data.index('CREATE INDEX index_dogs_on_cats_id ON dogs USING btree (cats_id);')
    end
  end

  private

  def connection
    ActiveRecord::Base.connection
  end

  def tmp_sql_filename
    File.expand_path('../tmp/tmp.sql', ::File.dirname(__FILE__))
  end

  def setup_database_tasks
    FileUtils.rm_f(tmp_sql_filename)
    FileUtils.mkdir_p(::File.dirname(tmp_sql_filename))
    ActiveRecord::Tasks::DatabaseTasks.create(TasksTest.new_database_config)
  end

end
