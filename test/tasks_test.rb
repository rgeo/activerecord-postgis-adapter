require 'test_helper'
require 'active_record/schema_dumper'

module RGeo
  module ActiveRecord  # :nodoc:
    module PostGISAdapter  # :nodoc:
      module Tests  # :nodoc:
        class TasksTest < BASE_TEST_CLASS  # :nodoc:
          DATABASE_CONFIG_PATH = ::File.dirname(__FILE__) + '/database.yml'
          OVERRIDE_DATABASE_CONFIG_PATH = ::File.dirname(__FILE__) + '/database_local.yml'

          class << self
            def before_open_database(args)
              @new_database_config = args[:config].merge('database' => 'postgis_adapter_test2')
              @new_database_config.stringify_keys!
            end
            attr_reader :new_database_config
          end

          include AdapterTestHelper

          def cleanup_tables
            ::ActiveRecord::Base.remove_connection
            ::ActiveRecord::Base.clear_active_connections!
            TasksTest::DEFAULT_AR_CLASS.connection.execute("DROP DATABASE IF EXISTS \"postgis_adapter_test2\"")
          end

          define_test_methods do
            def test_create_database_from_extension_in_public_schema
              ::ActiveRecord::Tasks::DatabaseTasks.create(TasksTest.new_database_config)
              ::ActiveRecord::Base.connection.select_values("SELECT * from public.spatial_ref_sys")
            end

            def test_empty_sql_dump
              filename = ::File.expand_path('../tmp/tmp.sql', ::File.dirname(__FILE__))
              ::FileUtils.rm_f(filename)
              ::FileUtils.mkdir_p(::File.dirname(filename))
              ::ActiveRecord::Tasks::DatabaseTasks.create(TasksTest.new_database_config.merge('schema_search_path' => 'public'))
              ::ActiveRecord::Tasks::DatabaseTasks.structure_dump(TasksTest.new_database_config, filename)
              sql = ::File.read(filename)
              assert(sql !~ /CREATE TABLE/)
            end

            def test_basic_geography_sql_dump
              filename = ::File.expand_path('../tmp/tmp.sql', ::File.dirname(__FILE__))
              ::FileUtils.rm_f(filename)
              ::FileUtils.mkdir_p(::File.dirname(filename))
              ::ActiveRecord::Tasks::DatabaseTasks.create(TasksTest.new_database_config.merge('schema_search_path' => 'public'))
              ::ActiveRecord::Base.connection.create_table(:spatial_test) do |t|
                t.point "latlon", :geographic => true
              end
              ::ActiveRecord::Tasks::DatabaseTasks.structure_dump(TasksTest.new_database_config, filename)
              data = ::File.read(filename)
              assert(data.index('latlon geography(Point,4326)'))
            end

            def test_empty_schema_dump
              filename = ::File.expand_path('../tmp/tmp.rb', ::File.dirname(__FILE__))
              ::FileUtils.rm_f(filename)
              ::FileUtils.mkdir_p(::File.dirname(filename))
              ::ActiveRecord::Tasks::DatabaseTasks.create(TasksTest.new_database_config.merge('schema_search_path' => 'public'))
              ::File.open(filename, "w:utf-8") do |file|
                ::ActiveRecord::SchemaDumper.dump(::ActiveRecord::Base.connection, file)
              end
              data = ::File.read(filename)
              assert(data.index('ActiveRecord::Schema'))
            end

            def test_basic_geometry_schema_dump
              filename = ::File.expand_path('../tmp/tmp.rb', ::File.dirname(__FILE__))
              ::FileUtils.rm_f(filename)
              ::FileUtils.mkdir_p(::File.dirname(filename))
              ::ActiveRecord::Tasks::DatabaseTasks.create(TasksTest.new_database_config.merge('schema_search_path' => 'public'))
              conn = ::ActiveRecord::Base.connection
              conn.create_table(:spatial_test) do |t|
                t.geometry 'object1'
                t.spatial "object2", :limit => {:srid=>conn.default_srid, :type=>"geometry"}
              end
              ::File.open(filename, "w:utf-8") do |file|
                ::ActiveRecord::SchemaDumper.dump(conn, file)
              end
              data = ::File.read(filename)
              assert(data.index("t.spatial \"object1\", limit: {:srid=>#{conn.default_srid}, :type=>\"geometry\"}"))
              assert(data.index("t.spatial \"object2\", limit: {:srid=>#{conn.default_srid}, :type=>\"geometry\"}"))
            end

            def test_basic_geography_schema_dump
              filename = ::File.expand_path('../tmp/tmp.rb', ::File.dirname(__FILE__))
              ::FileUtils.rm_f(filename)
              ::FileUtils.mkdir_p(::File.dirname(filename))
              ::ActiveRecord::Tasks::DatabaseTasks.create(TasksTest.new_database_config.merge('schema_search_path' => 'public'))
              conn = ::ActiveRecord::Base.connection
              conn.create_table(:spatial_test) do |t|
                t.point "latlon1", :geographic => true
                t.spatial "latlon2", :limit => {:srid=>4326, :type=>"point", :geographic=>true}
              end
              ::File.open(filename, "w:utf-8") do |file|
                ::ActiveRecord::SchemaDumper.dump(conn, file)
              end
              data = ::File.read(filename)
              assert(data.index('t.spatial "latlon1", limit: {:srid=>4326, :type=>"point", :geographic=>true}'))
              assert(data.index('t.spatial "latlon2", limit: {:srid=>4326, :type=>"point", :geographic=>true}'))
            end
          end
        end
      end
    end
  end
end
