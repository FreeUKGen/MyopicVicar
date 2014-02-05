class AddLatLonToPlace
require "#{Rails.root}/app/models/place"
     
 def self.process(type)
   number_found = 0
   number_not_found = 0
   Place.order_by(chapman_code: 1, place_name: 1).each do |place|
    if place.location.nil?
    #puts "\" #{place.place_name}\", #{place.chapman_code},not found"
    place.lat_and_lon_from_master_place_name
    number_found = number_found + 1 unless place.location.nil?
    #puts "\" #{place.place_name}\", #{place.chapman_code}, found" unless place.location.nil?
     number_not_found = number_not_found + 1 if place.location.nil?
     #puts "\" #{place.place_name}\", #{place.chapman_code}, still not found" if place.location.nil?
  else
    mod = place.place_name.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase
    location = MasterPlaceName.where(:chapman_code => place.chapman_code, :modified_place_name => mod).first
    unless location.nil?
   
    if (place.location[0] != location.latitude) || (place.location[1] != location.longitude)
      
      p "\" #{place.place_name}\", #{place.chapman_code} has location mismatch"
      p place.location

      p location.latitude
      p location.longitude
    end
  else
    p "\" #{place.place_name}\", #{place.chapman_code} has location in Place but not Master"
  end
   end #end if
  
  end #end do
   puts "#{number_found} places found and #{number_not_found} not found"
 end #end method
end