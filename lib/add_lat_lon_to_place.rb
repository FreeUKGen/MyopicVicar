class AddLatLonToPlace
require "#{Rails.root}/app/models/place"
     
 def self.process(type)
   number_found = 0
   number_not_found = 0
   Place.order_by(chapman_code: 1, place_name: 1).each do |p|
    p.lat_and_lon_from_master_place_name
    number_found = number_found + 1 unless p.location.nil?
     number_not_found = number_not_found + 1 if p.location.nil?
     puts "#{p.place_name}, #{p.chapman_code}" if p.location.nil?
   end
   puts "#{number_found} places found and #{number_not_found} not found"
  end
end