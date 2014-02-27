class AddLatLonToPlace
require "#{Rails.root}/app/models/place"
     
 def self.process(type)
   number_found = 0
   number_not_found = 0
   Place.order_by(chapman_code: 1, place_name: 1).each do |place|

    if type == "recreate" then
      place.location[0] = nil unless  place.location.nil?
      place.location[1] = nil unless  place.location.nil?
      place.master_place_lat = nil 
      place.master_place_lon = nil
      place.genuki_url = nil
    
    end #recreate

    if place.location.nil? || (place.location[0].nil? && place.location[1].nil?)
      
       place.save
       number_found = number_found + 1 unless place.location.nil?
       number_not_found = number_not_found + 1 if place.location.nil?
     
    else
     
       mod = place.place_name.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase
       location = MasterPlaceName.where(:chapman_code => place.chapman_code, :modified_place_name => mod).first

       unless location.nil?
        
          if (place.location[0] != location.latitude) || (place.location[1] != location.longitude) then
      
              p "\" #{place.place_name}\", #{place.chapman_code} has location mismatch"
              p place.location
              p location.latitude
              p location.longitude
          end # mismatch check
       else
         p "\" #{place.place_name}\", #{place.chapman_code} has location in Place but not Master"
       end # unless location nil
      
    end #end place if
   
     
  end #end do
   puts "#{number_found} places found and #{number_not_found} not found"
 end #end method
end