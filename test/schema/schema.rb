ActiveRecord::Schema.define do
  create_table :cities, force: true do |t|
    t.string :name
    t.text :long_name
    t.column 'latlon', :point
    t.column 'latlon3785', :point, :srid => 3785
    t.column 'latlon4326', :point, :geographic => true
    t.column 'path', :line_string, :srid => 3785
    t.spatial 'region', :limit => {:has_m => true, :srid => 3785, :type => :polygon}
    t.column 'province', :polygon, :has_m => true, :srid => 3785
    t.point 'location'
    t.geometry 'geometry_shortcut'
    t.geometry 'geography_shortcut', :geographic => true
  end

  add_index :cities, :latlon3785, spatial: true
end
