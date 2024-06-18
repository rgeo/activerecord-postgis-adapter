# frozen_string_literal: true

require_relative "../test_helper"

module PostGIS
  class BasicTest < ActiveSupport::TestCase
    def before
      reset_spatial_store
    end

    def test_version
      refute_nil ActiveRecord::ConnectionAdapters::PostGIS::VERSION
    end

    def test_postgis_available
      assert_equal "PostGIS", SpatialModel.connection.adapter_name
      assert_equal postgis_version, SpatialModel.connection.postgis_lib_version
      valid_version = ["2.", "3."].any? { |major_ver| SpatialModel.connection.postgis_lib_version.start_with? major_ver }
      assert valid_version
    end

    def test_arel_visitor
      visitor = Arel::Visitors::PostGIS.new(SpatialModel.connection)
      node = RGeo::ActiveRecord::SpatialConstantNode.new("POINT (1.0 2.0)")
      collector = Arel::Collectors::PlainString.new
      visitor.accept(node, collector)
      assert_equal "ST_GeomFromText('POINT (1.0 2.0)')", collector.value
    end

    def test_arel_visitor_will_not_visit_string
      visitor = Arel::Visitors::PostGIS.new(SpatialModel.connection)
      node = "POINT (1 2)"
      collector = Arel::Collectors::PlainString.new

      assert_raises(Arel::Visitors::UnsupportedVisitError) do
        visitor.accept(node, collector)
      end
    end

    def test_set_and_get_point
      create_model
      obj = SpatialModel.new
      assert_nil obj.latlon
      obj.latlon = factory.point(1.0, 2.0)
      assert_equal factory.point(1.0, 2.0), obj.latlon
      assert_equal 3785, obj.latlon.srid
    end

    def test_set_and_get_point_from_wkt
      create_model
      obj = SpatialModel.new
      assert_nil obj.latlon
      obj.latlon = "POINT(1 2)"
      assert_equal factory.point(1.0, 2.0), obj.latlon
      assert_equal 3785, obj.latlon.srid
    end

    def test_save_and_load_point
      create_model
      obj = SpatialModel.new
      obj.latlon = factory.point(1.0, 2.0)
      obj.save!
      id = obj.id
      obj2 = SpatialModel.find(id)
      assert_equal factory.point(1.0, 2.0), obj2.latlon
      assert_equal 3785, obj2.latlon.srid
      # assert_equal true, RGeo::Geos.is_geos?(obj2.latlon)
    end

    def test_save_and_load_geographic_point
      create_model
      obj = SpatialModel.new
      obj.latlon_geo = geographic_factory.point(1.0, 2.0)
      obj.save!
      id = obj.id
      obj2 = SpatialModel.find(id)
      assert_equal geographic_factory.point(1.0, 2.0), obj2.latlon_geo
      assert_equal 4326, obj2.latlon_geo.srid
      # assert_equal false, RGeo::Geos.is_geos?(obj2.latlon_geo)
    end

    def test_save_and_load_point_from_wkt
      create_model
      obj = SpatialModel.new
      obj.latlon = "POINT(1 2)"
      obj.save!
      id = obj.id
      obj2 = SpatialModel.find(id)
      assert_equal factory.point(1.0, 2.0), obj2.latlon
      assert_equal 3785, obj2.latlon.srid
    end

    def test_set_point_bad_wkt
      create_model
      obj = SpatialModel.create(latlon: "POINT (x)")
      assert_nil obj.latlon
    end

    def test_set_point_wkt_wrong_type
      create_model
      assert_raises(ActiveRecord::StatementInvalid) do
        SpatialModel.create(latlon: "LINESTRING(1 2, 3 4, 5 6)")
      end
    end

    def test_default_value
      create_model
      obj = SpatialModel.create
      assert_equal factory(srid: 0).point(0, 0), obj.default_latlon
    end

    def test_custom_factory
      klass = SpatialModel
      klass.connection.create_table(:spatial_models, force: true) do |t|
        t.st_polygon(:area, srid: 4326)
      end
      klass.reset_column_information
      custom_factory = RGeo::Geographic.spherical_factory(buffer_resolution: 8, srid: 4326)
      spatial_factory_store.register(custom_factory, geo_type: "polygon", srid: 4326)
      object = klass.new
      area = custom_factory.point(1, 2).buffer(3)
      object.area = area
      object.save!
      object.reload
      assert_equal area, object.area
    end

    def test_spatial_factory_attrs_parsing
      klass = SpatialModel
      klass.connection.create_table(:spatial_models, force: true) do |t|
        t.multi_polygon(:areas, srid: 4326)
      end
      klass.reset_column_information
      factory = RGeo::Cartesian.preferred_factory(srid: 4326)
      spatial_factory_store.register(factory, { srid: 4326,
                                                sql_type: "geometry",
                                                geo_type: "multi_polygon",
                                                has_z: false, has_m: false })

      # wrong factory for default
      spatial_factory_store.default = RGeo::Geographic.spherical_factory(srid: 4326)

      object = klass.new
      object.areas = "MULTIPOLYGON (((0 0, 0 1, 1 1, 1 0, 0 0)))"
      object.save!
      object.reload
      assert_equal(factory, object.areas.factory)
    end

    def test_readme_example
      geo_factory = RGeo::Geographic.spherical_factory(srid: 4326)
      spatial_factory_store.register(geo_factory, geo_type: "point", sql_type: "geography")

      klass = SpatialModel
      klass.connection.create_table(:spatial_models, force: true) do |t|
        t.column(:shape, :geometry)
        t.line_string(:path, srid: 3785)
        t.st_point(:latlon, geographic: true)
      end
      klass.reset_column_information
      assert_includes klass.columns.map(&:name), "shape"
      klass.connection.change_table(:spatial_models) do |t|
        t.index(:latlon, using: :gist)
      end

      object = klass.new
      object.latlon = "POINT(-122 47)"
      point = object.latlon
      assert_equal 47, point.latitude
      object.shape = point

      # test that shape column will not use geographic factory
      object.save!
      object.reload
      refute_equal geo_factory, object.shape.factory
    end

    def test_point_to_json
      create_model
      obj = SpatialModel.new
      assert_match(/"latlon":null/, obj.to_json)
      obj.latlon = factory.point(1.0, 2.0)
      assert_match(/"latlon":"POINT\s\(1(\.0)?\s2(\.0)?\)"/, obj.to_json)
    end

    def test_custom_column
      create_model
      rec = SpatialModel.new
      rec.latlon = "POINT(0 0)"
      rec.save
      refute_nil SpatialModel.select("CURRENT_TIMESTAMP as ts").first.ts
    end

    def test_multi_polygon_column
      SpatialModel.connection.create_table(:spatial_models, force: true) do |t|
        t.column "m_poly", :multi_polygon
      end
      SpatialModel.reset_column_information
      rec = SpatialModel.new
      wkt = "MULTIPOLYGON (((-73.97210545302842 40.782991711401195, " \
            "-73.97228912063449 40.78274091498208, " \
            "-73.97235226842568 40.78276752827304, " \
            "-73.97216860098405 40.783018324791776, " \
            "-73.97210545302842 40.782991711401195)))"
      rec.m_poly = wkt
      assert rec.save
      rec = SpatialModel.find(rec.id) # force reload
      assert RGeo::Feature::MultiPolygon.check_type(rec.m_poly)
      assert_equal wkt, rec.m_poly.to_s
    end

    private

    def create_model
      SpatialModel.connection.create_table(:spatial_models, force: true) do |t|
        t.column "latlon", :st_point, srid: 3785
        t.column "latlon_geo", :st_point, srid: 4326, geographic: true
        t.column "default_latlon", :st_point, srid: 0, default: "POINT(0.0 0.0)"
      end
      SpatialModel.reset_column_information
    end
  end
end
