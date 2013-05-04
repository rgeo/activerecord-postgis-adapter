# -----------------------------------------------------------------------------
#
# Tests for the PostGIS ActiveRecord adapter
#
# -----------------------------------------------------------------------------
# Copyright 2010-2012 Daniel Azuma
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# * Neither the name of the copyright holder, nor the names of any other
#   contributors to this software, may be used to endorse or promote products
#   derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# -----------------------------------------------------------------------------
;

require 'minitest/autorun'
require 'rgeo/active_record/adapter_test_helper'


module RGeo
  module ActiveRecord  # :nodoc:
    module PostGISAdapter  # :nodoc:
      module Tests  # :nodoc:

        class TestTasks < ::MiniTest::Unit::TestCase  # :nodoc:

          DATABASE_CONFIG_PATH = ::File.dirname(__FILE__)+'/database.yml'
          OVERRIDE_DATABASE_CONFIG_PATH = ::File.dirname(__FILE__)+'/database_local.yml'

          class << self
            def before_open_database(args_)
              @new_database_config = args_[:config].merge('database' => 'postgis_adapter_test2')
              @new_database_config.stringify_keys!
            end
            attr_reader :new_database_config
          end

          include AdapterTestHelper


          def cleanup_tables
            ::ActiveRecord::Base.remove_connection
            ::ActiveRecord::Base.clear_active_connections!
            TestTasks::DEFAULT_AR_CLASS.connection.execute("DROP DATABASE IF EXISTS \"postgis_adapter_test2\"")
          end


          define_test_methods do


            def test_create_database_from_extension_in_postgis_schema
              unless defined?(::ActiveRecord::ConnectionAdapters::PostGISAdapter::PostGISDatabaseTasks)
                skip('No task tests for Rails 3')
              end
              ::ActiveRecord::Tasks::DatabaseTasks.create(TestTasks.new_database_config.merge('schema_search_path' => 'public,postgis'))
              ::ActiveRecord::Base.connection.select_values("SELECT * from postgis.spatial_ref_sys")
            end


            def test_create_database_from_extension_in_public_schema
              unless defined?(::ActiveRecord::ConnectionAdapters::PostGISAdapter::PostGISDatabaseTasks)
                skip('No task tests for Rails 3')
              end
              ::ActiveRecord::Tasks::DatabaseTasks.create(TestTasks.new_database_config)
              ::ActiveRecord::Base.connection.select_values("SELECT * from public.spatial_ref_sys")
            end


            def test_empty_sql_dump
              unless defined?(::ActiveRecord::ConnectionAdapters::PostGISAdapter::PostGISDatabaseTasks)
                skip('No task tests for Rails 3')
              end
              filename_ = ::File.expand_path('../tmp/tmp.sql', ::File.dirname(__FILE__))
              ::FileUtils.rm_f(filename_)
              ::FileUtils.mkdir_p(::File.dirname(filename_))
              ::ActiveRecord::Tasks::DatabaseTasks.create(TestTasks.new_database_config.merge('schema_search_path' => 'public,postgis'))
              ::ActiveRecord::Tasks::DatabaseTasks.structure_dump(TestTasks.new_database_config, filename_)
              sql_ = ::File.read(filename_)
              assert(sql_ !~ /CREATE/)
            end


            def test_basic_geography_sql_dump
              unless defined?(::ActiveRecord::ConnectionAdapters::PostGISAdapter::PostGISDatabaseTasks)
                skip('No task tests for Rails 3')
              end
              filename_ = ::File.expand_path('../tmp/tmp.sql', ::File.dirname(__FILE__))
              ::FileUtils.rm_f(filename_)
              ::FileUtils.mkdir_p(::File.dirname(filename_))
              ::ActiveRecord::Tasks::DatabaseTasks.create(TestTasks.new_database_config.merge('schema_search_path' => 'public,postgis'))
              ::ActiveRecord::Base.connection.create_table(:spatial_test) do |t_|
                t_.point "latlon", :geographic => true
              end
              ::ActiveRecord::Tasks::DatabaseTasks.structure_dump(TestTasks.new_database_config, filename_)
              data_ = ::File.read(filename_)
              assert(data_.index('latlon postgis.geography(Point,4326)'))
            end


            def test_empty_schema_dump
              unless defined?(::ActiveRecord::ConnectionAdapters::PostGISAdapter::PostGISDatabaseTasks)
                skip('No task tests for Rails 3')
              end
              filename_ = ::File.expand_path('../tmp/tmp.rb', ::File.dirname(__FILE__))
              ::FileUtils.rm_f(filename_)
              ::FileUtils.mkdir_p(::File.dirname(filename_))
              ::ActiveRecord::Tasks::DatabaseTasks.create(TestTasks.new_database_config.merge('schema_search_path' => 'public,postgis'))
              require 'active_record/schema_dumper'
              ::File.open(filename_, "w:utf-8") do |file_|
                ::ActiveRecord::SchemaDumper.dump(::ActiveRecord::Base.connection, file_)
              end
              data_ = ::File.read(filename_)
              assert(data_.index('ActiveRecord::Schema'))
            end


            def test_basic_geometry_schema_dump
              unless defined?(::ActiveRecord::ConnectionAdapters::PostGISAdapter::PostGISDatabaseTasks)
                skip('No task tests for Rails 3')
              end
              filename_ = ::File.expand_path('../tmp/tmp.rb', ::File.dirname(__FILE__))
              ::FileUtils.rm_f(filename_)
              ::FileUtils.mkdir_p(::File.dirname(filename_))
              ::ActiveRecord::Tasks::DatabaseTasks.create(TestTasks.new_database_config.merge('schema_search_path' => 'public,postgis'))
              conn_ = ::ActiveRecord::Base.connection
              conn_.create_table(:spatial_test) do |t_|
                t_.geometry 'object1'
                t_.spatial "object2", :limit => {:srid=>conn_.default_srid, :type=>"geometry"}
              end
              require 'active_record/schema_dumper'
              ::File.open(filename_, "w:utf-8") do |file_|
                ::ActiveRecord::SchemaDumper.dump(conn_, file_)
              end
              data_ = ::File.read(filename_)
              assert(data_.index("t.spatial \"object1\", limit: {:srid=>#{conn_.default_srid}, :type=>\"geometry\"}"))
              assert(data_.index("t.spatial \"object2\", limit: {:srid=>#{conn_.default_srid}, :type=>\"geometry\"}"))
            end


            def test_basic_geography_schema_dump
              unless defined?(::ActiveRecord::ConnectionAdapters::PostGISAdapter::PostGISDatabaseTasks)
                skip('No task tests for Rails 3')
              end
              filename_ = ::File.expand_path('../tmp/tmp.rb', ::File.dirname(__FILE__))
              ::FileUtils.rm_f(filename_)
              ::FileUtils.mkdir_p(::File.dirname(filename_))
              ::ActiveRecord::Tasks::DatabaseTasks.create(TestTasks.new_database_config.merge('schema_search_path' => 'public,postgis'))
              conn_ = ::ActiveRecord::Base.connection
              conn_.create_table(:spatial_test) do |t_|
                t_.point "latlon1", :geographic => true
                t_.spatial "latlon2", :limit => {:srid=>4326, :type=>"point", :geographic=>true}
              end
              require 'active_record/schema_dumper'
              ::File.open(filename_, "w:utf-8") do |file_|
                ::ActiveRecord::SchemaDumper.dump(conn_, file_)
              end
              data_ = ::File.read(filename_)
              assert(data_.index('t.spatial "latlon1", limit: {:srid=>4326, :type=>"point", :geographic=>true}'))
              assert(data_.index('t.spatial "latlon2", limit: {:srid=>4326, :type=>"point", :geographic=>true}'))
            end


          end

        end

      end
    end
  end
end
