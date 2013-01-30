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

require 'test/unit'
require 'rgeo/active_record/adapter_test_helper'


module RGeo
  module ActiveRecord  # :nodoc:
    module PostGISAdapter  # :nodoc:
      module Tests  # :nodoc:

        class TestDDL < ::Test::Unit::TestCase  # :nodoc:

          DATABASE_CONFIG_PATH = ::File.dirname(__FILE__)+'/database.yml'
          OVERRIDE_DATABASE_CONFIG_PATH = ::File.dirname(__FILE__)+'/database_local.yml'
          include AdapterTestHelper

          define_test_methods do


            def test_create_simple_geometry
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.column 'latlon', :geometry
              end
              assert_equal(1, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
              col_ = klass_.columns.last
              assert_equal(::RGeo::Feature::Geometry, col_.geometric_type)
              assert_equal(true, col_.has_spatial_constraints?)
              assert_equal(false, col_.geographic?)
              assert_equal(if(klass_.connection.postgis_lib_version >= "2") then 0 else -1 end, col_.srid)
              assert(klass_.cached_attributes.include?('latlon'))
              klass_.connection.drop_table(:spatial_test)
              assert_equal(0, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
            end


            # no_constraints no longer supported in PostGIS 2.0
            def _test_create_no_constraints_geometry
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.column 'geom', :geometry, :limit => {:no_constraints => true}
              end
              assert_equal(0, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
              col_ = klass_.columns.last
              assert_equal(::RGeo::Feature::Geometry, col_.geometric_type)
              assert_equal(false, col_.geographic?)
              assert_equal(false, col_.has_spatial_constraints?)
              assert_nil(col_.srid)
              assert(klass_.cached_attributes.include?('geom'))
              klass_.connection.drop_table(:spatial_test)
              assert_equal(0, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
            end


            def test_create_simple_geography
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.column 'latlon', :geometry, :geographic => true
              end
              col_ = klass_.columns.last
              assert_equal(::RGeo::Feature::Geometry, col_.geometric_type)
              assert_equal(true, col_.has_spatial_constraints?)
              assert_equal(true, col_.geographic?)
              assert_equal(4326, col_.srid)
              assert(klass_.cached_attributes.include?('latlon'))
              assert_equal(0, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
            end


            def test_create_point_geometry
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.column 'latlon', :point
              end
              assert_equal(::RGeo::Feature::Point, klass_.columns.last.geometric_type)
              assert(klass_.cached_attributes.include?('latlon'))
            end


            def test_create_geometry_with_index
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.column 'latlon', :geometry
              end
              klass_.connection.change_table(:spatial_test) do |t_|
                t_.index([:latlon], :spatial => true)
              end
              assert(klass_.connection.indexes(:spatial_test).last.spatial)
            end


            def test_add_geometry_column
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.column('latlon', :geometry)
              end
              klass_.connection.change_table(:spatial_test) do |t_|
                t_.column('geom2', :point, :srid => 4326)
                t_.column('name', :string)
              end
              assert_equal(2, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
              cols_ = klass_.columns
              assert_equal(::RGeo::Feature::Geometry, cols_[-3].geometric_type)
              assert_equal(if(klass_.connection.postgis_lib_version >= "2") then 0 else -1 end, cols_[-3].srid)
              assert_equal(true, cols_[-3].has_spatial_constraints?)
              assert_equal(::RGeo::Feature::Point, cols_[-2].geometric_type)
              assert_equal(4326, cols_[-2].srid)
              assert_equal(false, cols_[-2].geographic?)
              assert_equal(true, cols_[-2].has_spatial_constraints?)
              assert_nil(cols_[-1].geometric_type)
              assert_equal(false, cols_[-1].has_spatial_constraints?)
            end


            # no_constraints no longer supported in PostGIS 2.0
            def _test_add_no_constraints_geometry_column
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.column('latlon', :geometry)
              end
              klass_.connection.change_table(:spatial_test) do |t_|
                t_.column('geom2', :geometry, :no_constraints => true)
                t_.column('name', :string)
              end
              assert_equal(1, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
              cols_ = klass_.columns
              assert_equal(::RGeo::Feature::Geometry, cols_[-3].geometric_type)
              assert_equal(if(klass_.connection.postgis_lib_version >= "2") then 0 else -1 end, cols_[-3].srid)
              assert_equal(true, cols_[-3].has_spatial_constraints?)
              assert_equal(::RGeo::Feature::Geometry, cols_[-2].geometric_type)
              assert_nil(cols_[-2].srid)
              assert_equal(false, cols_[-2].geographic?)
              assert_equal(false, cols_[-2].has_spatial_constraints?)
              assert_nil(cols_[-1].geometric_type)
              assert_equal(false, cols_[-1].has_spatial_constraints?)
            end


            def test_add_geography_column
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.column('latlon', :geometry)
              end
              klass_.connection.change_table(:spatial_test) do |t_|
                t_.column('geom2', :point, :srid => 4326, :geographic => true)
                t_.column('name', :string)
              end
              assert_equal(1, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
              cols_ = klass_.columns
              assert_equal(::RGeo::Feature::Geometry, cols_[-3].geometric_type)
              assert_equal(if(klass_.connection.postgis_lib_version >= "2") then 0 else -1 end, cols_[-3].srid)
              assert_equal(true, cols_[-3].has_spatial_constraints?)
              assert_equal(::RGeo::Feature::Point, cols_[-2].geometric_type)
              assert_equal(4326, cols_[-2].srid)
              assert_equal(true, cols_[-2].geographic?)
              assert_equal(true, cols_[-2].has_spatial_constraints?)
              assert_nil(cols_[-1].geometric_type)
              assert_equal(false, cols_[-1].has_spatial_constraints?)
            end


            def test_drop_geometry_column
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.column('latlon', :geometry)
                t_.column('geom2', :point, :srid => 4326)
              end
              klass_.connection.change_table(:spatial_test) do |t_|
                t_.remove('geom2')
              end
              assert_equal(1, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
              cols_ = klass_.columns
              assert_equal(::RGeo::Feature::Geometry, cols_[-1].geometric_type)
              assert_equal('latlon', cols_[-1].name)
              assert_equal(if(klass_.connection.postgis_lib_version >= "2") then 0 else -1 end, cols_[-1].srid)
              assert_equal(false, cols_[-1].geographic?)
            end


            def test_drop_geography_column
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.column('latlon', :geometry)
                t_.column('geom2', :point, :srid => 4326, :geographic => true)
                t_.column('geom3', :point, :srid => 4326)
              end
              klass_.connection.change_table(:spatial_test) do |t_|
                t_.remove('geom2')
              end
              assert_equal(2, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
              cols_ = klass_.columns
              assert_equal(::RGeo::Feature::Point, cols_[-1].geometric_type)
              assert_equal('geom3', cols_[-1].name)
              assert_equal(false, cols_[-1].geographic?)
              assert_equal(::RGeo::Feature::Geometry, cols_[-2].geometric_type)
              assert_equal('latlon', cols_[-2].name)
              assert_equal(false, cols_[-2].geographic?)
            end


            def test_create_simple_geometry_using_shortcut
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.geometry 'latlon'
              end
              assert_equal(1, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
              col_ = klass_.columns.last
              assert_equal(::RGeo::Feature::Geometry, col_.geometric_type)
              assert_equal(false, col_.geographic?)
              assert_equal(if(klass_.connection.postgis_lib_version >= "2") then 0 else -1 end, col_.srid)
              assert(klass_.cached_attributes.include?('latlon'))
              klass_.connection.drop_table(:spatial_test)
              assert_equal(0, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
            end


            # no_constraints no longer supported in PostGIS 2.0
            def _test_create_no_constraints_geometry_using_shortcut
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.spatial 'geom', :no_constraints => true
              end
              assert_equal(0, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
              col_ = klass_.columns.last
              assert_equal(::RGeo::Feature::Geometry, col_.geometric_type)
              assert_equal(false, col_.geographic?)
              assert_nil(col_.srid)
              assert(klass_.cached_attributes.include?('geom'))
              klass_.connection.drop_table(:spatial_test)
              assert_equal(0, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
            end


            def test_create_simple_geography_using_shortcut
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                # t_.method_missing(:geometry, 'latlon', :geographic => true)
                t_.geometry 'latlon', :geographic => true
              end
              col_ = klass_.columns.last
              assert_equal(::RGeo::Feature::Geometry, col_.geometric_type)
              assert_equal(true, col_.geographic?)
              assert_equal(4326, col_.srid)
              assert(klass_.cached_attributes.include?('latlon'))
              assert_equal(0, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
            end


            def test_create_point_geometry_using_shortcut
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.point 'latlon'
              end
              assert_equal(::RGeo::Feature::Point, klass_.columns.last.geometric_type)
              assert(klass_.cached_attributes.include?('latlon'))
            end


            def test_create_geometry_with_options
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.column 'region', :polygon, :has_m => true, :srid => 3785
              end
              assert_equal(1, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
              col_ = klass_.columns.last
              assert_equal(::RGeo::Feature::Polygon, col_.geometric_type)
              assert_equal(false, col_.geographic?)
              assert_equal(false, col_.has_z?)
              assert_equal(true, col_.has_m?)
              assert_equal(3785, col_.srid)
              assert_equal({:has_m => true, :type => 'polygon', :srid => 3785}, col_.limit)
              assert(klass_.cached_attributes.include?('region'))
              klass_.connection.drop_table(:spatial_test)
              assert_equal(0, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
            end


            def test_create_geometry_using_limit
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.spatial 'region', :limit => {:has_m => true, :srid => 3785, :type => :polygon}
              end
              assert_equal(1, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
              col_ = klass_.columns.last
              assert_equal(::RGeo::Feature::Polygon, col_.geometric_type)
              assert_equal(false, col_.geographic?)
              assert_equal(false, col_.has_z)
              assert_equal(true, col_.has_m)
              assert_equal(3785, col_.srid)
              assert_equal({:has_m => true, :type => 'polygon', :srid => 3785}, col_.limit)
              assert(klass_.cached_attributes.include?('region'))
              klass_.connection.drop_table(:spatial_test)
              assert_equal(0, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
            end


          end

        end

      end
    end
  end
end
