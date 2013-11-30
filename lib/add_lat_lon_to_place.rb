class AddLatLonToPlace
require "#{Rails.root}/app/models/place"
     
 def self.process(type)
   Place.order_by(chapman_code: 1, place_name: 1).each do |p|
    p.lat_and_lon_from_master_place_name
   end
  end
end