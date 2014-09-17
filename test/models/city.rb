class City < ActiveRecord::Base
end

class SimpleCity < ActiveRecord::Base
  self.table_name = 'cities'
  self.set_rgeo_factory_for_column(:latlon4326, RGeo::Geographic.simple_mercator_factory)
end