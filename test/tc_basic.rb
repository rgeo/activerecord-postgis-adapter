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

require 'minitest/unit'
require 'rgeo/active_record/adapter_test_helper'


module RGeo
  module ActiveRecord  # :nodoc:
    module PostGISAdapter  # :nodoc:
      module Tests  # :nodoc:

        class TestBasic < ::MiniTest::Unit::TestCase  # :nodoc:

          DATABASE_CONFIG_PATH = ::File.dirname(__FILE__)+'/database.yml'
          OVERRIDE_DATABASE_CONFIG_PATH = ::File.dirname(__FILE__)+'/database_local.yml'
          include AdapterTestHelper

          define_test_methods do


            def populate_ar_class(content_)
              klass_ = create_ar_class
              case content_
              when :mercator_point
                klass_.connection.create_table(:spatial_test) do |t_|
                  t_.column 'latlon', :point, :srid => 3785
                end
              when :latlon_point_geographic
                klass_.connection.create_table(:spatial_test) do |t_|
                  t_.column 'latlon', :point, :srid => 4326, :geographic => true
                end
              when :no_constraints
                klass_.connection.create_table(:spatial_test) do |t_|
                  t_.column 'geo', :geometry, :no_constraints => true
                end
              end
              klass_
            end


            def test_version
              refute_nil(::ActiveRecord::ConnectionAdapters::PostGISAdapter::VERSION)
            end


            def test_postgis_available
              connection_ = create_ar_class.connection
              assert_equal('PostGIS', connection_.adapter_name)
              refute_nil(connection_.postgis_lib_version)
            end


            def test_set_and_get_point
              klass_ = populate_ar_class(:mercator_point)
              obj_ = klass_.new
              assert_nil(obj_.latlon)
              obj_.latlon = @factory.point(1, 2)
              assert_equal(@factory.point(1, 2), obj_.latlon)
              assert_equal(3785, obj_.latlon.srid)
            end


            def test_set_and_get_point_from_wkt
              klass_ = populate_ar_class(:mercator_point)
              obj_ = klass_.new
              assert_nil(obj_.latlon)
              obj_.latlon = 'POINT(1 2)'
              assert_equal(@factory.point(1, 2), obj_.latlon)
              assert_equal(3785, obj_.latlon.srid)
            end


            def test_save_and_load_point
              klass_ = populate_ar_class(:mercator_point)
              obj_ = klass_.new
              obj_.latlon = @factory.point(1, 2)
              obj_.save!
              id_ = obj_.id
              obj2_ = klass_.find(id_)
              assert_equal(@factory.point(1, 2), obj2_.latlon)
              assert_equal(3785, obj2_.latlon.srid)
              assert_equal(true, ::RGeo::Geos.is_geos?(obj2_.latlon))
            end


            def test_save_and_load_geographic_point
              klass_ = populate_ar_class(:latlon_point_geographic)
              obj_ = klass_.new
              obj_.latlon = @factory.point(1, 2)
              obj_.save!
              id_ = obj_.id
              obj2_ = klass_.find(id_)
              assert_equal(@geographic_factory.point(1, 2), obj2_.latlon)
              assert_equal(4326, obj2_.latlon.srid)
              assert_equal(false, ::RGeo::Geos.is_geos?(obj2_.latlon))
            end


            def test_save_and_load_point_from_wkt
              klass_ = populate_ar_class(:mercator_point)
              obj_ = klass_.new
              obj_.latlon = 'POINT(1 2)'
              obj_.save!
              id_ = obj_.id
              obj2_ = klass_.find(id_)
              assert_equal(@factory.point(1, 2), obj2_.latlon)
              assert_equal(3785, obj2_.latlon.srid)
            end


            def test_set_point_bad_wkt
              klass_ = populate_ar_class(:mercator_point)
              obj_ = klass_.create(:latlon => 'POINT (x)')
              assert_nil(obj_.latlon)
            end


            def test_custom_factory
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.point(:latlon, :srid => 4326)
              end
              factory_ = ::RGeo::Geographic.simple_mercator_factory
              klass_.class_eval do
                set_rgeo_factory_for_column(:latlon, factory_)
              end
              rec_ = klass_.new
              rec_.latlon = 'POINT(-122 47)'
              assert_equal(factory_, rec_.latlon.factory)
              rec_.save!
              assert_equal(factory_, rec_.latlon.factory)
              rec2_ = klass_.find(rec_.id)
              assert_equal(factory_, rec2_.latlon.factory)
            end


            def test_readme_example
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.column(:shape, :geometry)
                t_.line_string(:path, :srid => 3785)
                t_.point(:latlon, :geographic => true)
              end
              klass_.connection.change_table(:spatial_test) do |t_|
                t_.index(:latlon, :spatial => true)
              end
              klass_.class_eval do
                self.rgeo_factory_generator = ::RGeo::Geos.method(:factory)
                set_rgeo_factory_for_column(:latlon, ::RGeo::Geographic.spherical_factory)
              end
              rec_ = klass_.new
              rec_.latlon = 'POINT(-122 47)'
              loc_ = rec_.latlon
              assert_equal(47, loc_.latitude)
              rec_.shape = loc_
              assert_equal(true, ::RGeo::Geos.is_geos?(rec_.shape))
            end


            # no_constraints no longer supported in PostGIS 2.0
            def _test_save_and_load_no_constraints
              klass_ = populate_ar_class(:no_constraints)
              factory1_ = ::RGeo::Cartesian.preferred_factory(:srid => 3785)
              factory2_ = ::RGeo::Cartesian.preferred_factory(:srid => 2000)
              obj_ = klass_.new
              obj_.geo = factory1_.point(1, 2)
              obj_.save!
              id_ = obj_.id
              obj2_ = klass_.find(id_)
              assert_equal(factory1_.point(1, 2), obj2_.geo)
              assert_equal(3785, obj2_.geo.srid)
              obj2_.geo = factory2_.point(3, 4)
              obj2_.save!
              obj3_ = klass_.find(id_)
              assert_equal(factory2_.point(3,4), obj3_.geo)
              assert_equal(2000, obj3_.geo.srid)
            end


            def test_point_to_json
              klass_ = populate_ar_class(:mercator_point)
              obj_ = klass_.new
              assert_match(/"latlon":null/, obj_.to_json)
              obj_.latlon = @factory.point(1, 2)
              assert_match(/"latlon":"POINT\s\(1\.0\s2\.0\)"/, obj_.to_json)
            end


            def test_custom_column
              klass_ = populate_ar_class(:mercator_point)
              rec_ = klass_.new
              rec_.latlon = 'POINT(0 0)'
              rec_.save
              refute_nil(klass_.select("CURRENT_TIMESTAMP as ts").first.ts)
            end


          end

        end

      end
    end
  end
end
