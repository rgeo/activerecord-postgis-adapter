ActiveRecord::Schema.define do
  create_table :geometries, force: true do |t|
    t.string :name
    t.text :long_name
    t.st_point 'point'
    t.st_point 'point_with_srid_3785', srid: 3785
    t.st_linestring 'linestring_with_srid', limit: 3785
    t.st_polygon_z 'polygonz_with_srid', srid: 3785
    t.st_polygon_z_m 'polygonzm_with_srid', srid: 3785
    t.st_geometry 'geometry_without_srid'
    t.st_geometry 'geometry_with_srid', srid: 3785
    t.st_geometry_z 'geometryz_with_srid', srid: 3785
    t.st_geometry_z_m 'geometryzm_with_srid', limit: 3785
    t.st_point 'geographic_point', precision: true
  end

  add_index :geometries, :point
end
