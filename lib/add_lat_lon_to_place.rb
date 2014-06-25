class AddLatLonToPlace
require "#{Rails.root}/app/models/place"
require "#{Rails.root}/app/models/master_place_name"

include Mongoid::Document

def initialize
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    
  end
     
 def self.process(type)
  number_processed = 0
   number_added = 0
   number_not_found = 0
   number_updated = 0
   Place.order_by(chapman_code: 1, place_name: 1).each do |place|
   number_processed = number_processed + 1
    if type == "recreate" then
      place.location[0] = nil unless  place.location.nil?
      place.location[1] = nil unless  place.location.nil?
      place.master_place_lat = nil 
      place.master_place_lon = nil
      place.genuki_url = nil
    
    end #recreate

   

         
     
       location = MasterPlaceName.where(:chapman_code => place.chapman_code, :place_name => place.place_name ,:disabled.ne => "true").first

       if location.nil? then
           mod = place.place_name.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase
          location = MasterPlaceName.where(:chapman_code => place.chapman_code, :modified_place_name => mod,:disabled.ne => "true").first
        end
       unless location.nil?
        #master has a loaction for this place
          if place.location.nil? || (place.location[0].nil? && place.location[1].nil?)
            #place has no location
            place.location = [location.latitude, location.longitude]
              place.master_place_lat = location.latitude
              place.master_place_lon = location.longitude
              place.genuki_url = location.genuki_url
               # p "\" #{place.place_name}\", #{place.chapman_code} is added" 
              number_added = number_added  + 1

            place.save
          else
            #place has a location
            if (place.location[0] == location.latitude) && (place.location[1] == location.longitude) && (place.genuki_url == location.genuki_url)
             #they are the same
            #p "\" #{place.place_name}\", #{place.chapman_code} and genuki link is up to date"
            else
            #they are different
             place.location[0] = location.latitude
             place.location[1] == location.longitude
              place.master_place_lat = location.latitude
              place.master_place_lon = location.longitude
              place.genuki_url = location.genuki_url
                #p "\" #{place.place_name}\", #{place.chapman_code} and genuki link is updated" 
              number_updated = number_updated + 1 
            place.save

            end
          end
       else
         mod = place.place_name.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase




         #p "\" #{place.place_name}\", #{place.chapman_code} has no location in Master"
         number_not_found = number_not_found + 1
       end # unless location nil
       
     
   
       
   
 
     
  end #end do
   puts "#{number_processed} places processed, #{number_added} places added #{number_updated} updated and #{number_not_found} not found"
 end #end method
end
