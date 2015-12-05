class MissingModifiedPlaceNames

require 'chapman_code'
require "place"
include Mongoid::Document

  def self.process(limit)
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
  	file_for_warning_messages = "log/check_modified_place_name_messages.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
    message_file = File.new(file_for_warning_messages, "w")
  	limit = limit.to_i
    puts "checking #{limit} documents for missing modified_place_name in the place collection"
    
  	missing_records = 0
    number = 0
  	Place.each do |place|
      number = number + 1
      if place.modified_place_name.blank? || place.place_name.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase != place.modified_place_name
    	  missing_records = missing_records + 1
        
    	  puts "\" #{place.chapman_code}\",\" #{place.place_name}\", \" #{place.modified_place_name}\", missing/incorrect modified place name" 
        message_file.puts   "\" #{place.chapman_code}\",\" #{place.place_name}\",\" #{place.modified_place_name}\", missing/incorrect modified place name" 
        break if  missing_records == limit
        place.update_attribute(:modified_place_name, place.place_name.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase)
      end # my entry if
    end #place
    puts "There were #{missing_records} missing/incorrect modified_place_names in #{number} processed records"
    
  end
end