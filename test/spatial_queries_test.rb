require 'minitest/autorun'
require 'rgeo/active_record/adapter_test_helper'

module RGeo
  module ActiveRecord  # :nodoc:
    module PostGISAdapter  # :nodoc:
      module Tests  # :nodoc:
        class SpatialQueriesTest < ::MiniTest::Test  # :nodoc:

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
              obj_.latlon = @factory.point(1.0, 2.0)
              obj_.save!
              id_ = obj_.id
              obj2_ = klass_.where(:latlon => @factory.multi_point([@factory.point(1.0, 2.0)])).first
              refute_nil(obj2_)
              assert_equal(id_, obj2_.id)
              obj3_ = klass_.where(:latlon => @factory.point(2.0, 2.0)).first
              assert_nil(obj3_)
            end

            def test_query_point_wkt
              klass_ = populate_ar_class(:mercator_point)
              obj_ = klass_.new
              obj_.latlon = @factory.point(1.0, 2.0)
              obj_.save!
              id_ = obj_.id
              obj2_ = klass_.where(:latlon => 'SRID=3785;POINT(1 2)').first
              refute_nil(obj2_)
              assert_equal(id_, obj2_.id)
              obj3_ = klass_.where(:latlon => 'SRID=3785;POINT(2 2)').first
              assert_nil(obj3_)
            end

            if ::RGeo::ActiveRecord.spatial_expressions_supported?

              def test_query_st_distance
                klass_ = populate_ar_class(:mercator_point)
                obj_ = klass_.new
                obj_.latlon = @factory.point(1.0, 2.0)
                obj_.save!
                id_ = obj_.id
                obj2_ = klass_.where(klass_.arel_table[:latlon].st_distance('SRID=3785;POINT(2 3)').lt(2)).first
                refute_nil(obj2_)
                assert_equal(id_, obj2_.id)
                obj3_ = klass_.where(klass_.arel_table[:latlon].st_distance('SRID=3785;POINT(2 3)').gt(2)).first
                assert_nil(obj3_)
              end

              def test_query_st_distance_from_constant
                klass_ = populate_ar_class(:mercator_point)
                obj_ = klass_.new
                obj_.latlon = @factory.point(1.0, 2.0)
                obj_.save!
                id_ = obj_.id
                obj2_ = klass_.where(::Arel.spatial('SRID=3785;POINT(2 3)').st_distance(klass_.arel_table[:latlon]).lt(2)).first
                refute_nil(obj2_)
                assert_equal(id_, obj2_.id)
                obj3_ = klass_.where(::Arel.spatial('SRID=3785;POINT(2 3)').st_distance(klass_.arel_table[:latlon]).gt(2)).first
                assert_nil(obj3_)
              end

              def test_query_st_length
                klass_ = populate_ar_class(:path_linestring)
                obj_ = klass_.new
                obj_.path = @factory.line(@factory.point(1.0, 2.0), @factory.point(3.0, 2.0))
                obj_.save!
                id_ = obj_.id
                obj2_ = klass_.where(klass_.arel_table[:path].st_length.eq(2)).first
                refute_nil(obj2_)
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
