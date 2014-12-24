class Geometry < ActiveRecord::Base
  self.table_name = 'geometries'
end

class SimpleGeometry < Geometry
  self.set_rgeo_factory_for_column(:geographic_point, RGeo::Geographic.simple_mercator_factory)
end