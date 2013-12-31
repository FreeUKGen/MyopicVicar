class AddLatLonToPlace
require "#{Rails.root}/app/models/place"
     
 def self.process(type)
   number_found = 0
   number_not_found = 0
   Place.order_by(chapman_code: 1, place_name: 1).each do |p|
    if type == "rebuild" then
     p.location = nil
     p.genuki_url = nil
     p.master_place_lat = nil
     p.master_place_lon = nil
    end
    p.lat_and_lon_from_master_place_name
    number_found = number_found + 1 unless p.location[0] == p.location[1]
     number_not_found = number_not_found + 1 if p.location[0] == p.location[1]
     puts "\" #{p.place_name}\", #{p.chapman_code},not found" if p.location[0] == p.location[1]
     break if number_not_found == 10
   end
   puts "#{number_found} places found and #{number_not_found} not found"
  end
end