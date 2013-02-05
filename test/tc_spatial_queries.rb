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

        class TestSpatialQueries < ::MiniTest::Unit::TestCase  # :nodoc:

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
              when :path_linestring
                klass_.connection.create_table(:spatial_test) do |t_|
                  t_.column 'path', :line_string, :srid => 3785
                end
              end
              klass_
            end


            def test_query_point
              klass_ = populate_ar_class(:mercator_point)
              obj_ = klass_.new
              obj_.latlon = @factory.point(1, 2)
              obj_.save!
              id_ = obj_.id
              obj2_ = klass_.where(:latlon => @factory.multi_point([@factory.point(1, 2)])).first
              assert_equal(id_, obj2_.id)
              obj3_ = klass_.where(:latlon => @factory.point(2, 2)).first
              assert_nil(obj3_)
            end


            def test_query_point_wkt
              klass_ = populate_ar_class(:mercator_point)
              obj_ = klass_.new
              obj_.latlon = @factory.point(1, 2)
              obj_.save!
              id_ = obj_.id
              obj2_ = klass_.where(:latlon => 'SRID=3785;POINT(1 2)').first
              assert_equal(id_, obj2_.id)
              obj3_ = klass_.where(:latlon => 'SRID=3785;POINT(2 2)').first
              assert_nil(obj3_)
            end


            if ::RGeo::ActiveRecord.spatial_expressions_supported?


              def test_query_st_distance
                klass_ = populate_ar_class(:mercator_point)
                obj_ = klass_.new
                obj_.latlon = @factory.point(1, 2)
                obj_.save!
                id_ = obj_.id
                obj2_ = klass_.where(klass_.arel_table[:latlon].st_distance('SRID=3785;POINT(2 3)').lt(2)).first
                assert_equal(id_, obj2_.id)
                obj3_ = klass_.where(klass_.arel_table[:latlon].st_distance('SRID=3785;POINT(2 3)').gt(2)).first
                assert_nil(obj3_)
              end


              def test_query_st_distance_from_constant
                klass_ = populate_ar_class(:mercator_point)
                obj_ = klass_.new
                obj_.latlon = @factory.point(1, 2)
                obj_.save!
                id_ = obj_.id
                obj2_ = klass_.where(::Arel.spatial('SRID=3785;POINT(2 3)').st_distance(klass_.arel_table[:latlon]).lt(2)).first
                assert_equal(id_, obj2_.id)
                obj3_ = klass_.where(::Arel.spatial('SRID=3785;POINT(2 3)').st_distance(klass_.arel_table[:latlon]).gt(2)).first
                assert_nil(obj3_)
              end


              def test_query_st_length
                klass_ = populate_ar_class(:path_linestring)
                obj_ = klass_.new
                obj_.path = @factory.line(@factory.point(1, 2), @factory.point(3, 2))
                obj_.save!
                id_ = obj_.id
                obj2_ = klass_.where(klass_.arel_table[:path].st_length.eq(2)).first
                assert_equal(id_, obj2_.id)
                obj3_ = klass_.where(klass_.arel_table[:path].st_length.gt(3)).first
                assert_nil(obj3_)
              end


            else

              puts "WARNING: The current Arel does not support named functions. Spatial expression tests skipped."

            end


          end

        end

      end
    end
  end
end
