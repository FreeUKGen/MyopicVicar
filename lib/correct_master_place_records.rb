class CorrectMasterPlaceRecords


 
require 'chapman_code'


require "#{Rails.root}/app/models/master_place_name"

include Mongoid::Document
 


 
  def initialize
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    
  end

  def self.process(type)
  	file_for_warning_messages = "#{Rails.root}/log/master_places.csv"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
    output_file = File.new(file_for_warning_messages, "w")
  	
    freereg1_csv_file = CorrectMasterPlaceRecords.new
  	missing_search_record = Array.new
  	
  	puts "Correcting Master Place Records for incorrect processing of modified place name on update"
  	record_number = 0
  	missing_records = 0
  	
  	places = MasterPlaceName.all
    places.each do |place| 
      record_number = record_number + 1
      unless place.place_name.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase ==   place.modified_place_name
        missing_records = missing_records + 1
        p "incorrect match"
         p place.place_name
        p place.place_name.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase 
        p place.modified_place_name

        place.modified_place_name = place.place_name.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase
        place.save!
  	 end
  	end  
    puts "checked #{record_number} entries there were #{missing_records} incorrect master place records"
   
  end
end