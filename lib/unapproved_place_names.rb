class UnapprovedPlaceNames

require 'chapman_code'
require "place"
include Mongoid::Document

  def self.process(limit)
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
  	file_for_warning_messages = "log/unapproved_place_name_messages.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
    message_file = File.new(file_for_warning_messages, "w")
  	limit = limit.to_i
    puts "checking #{limit} documents for missing modified_place_name in the place collection"
    
  	missing_records = 0
    number = 0
  	Place.each do |place|
      number = number + 1
      if place.error_flag == "Place name is not approved" && place.disabled == "false"
    	  missing_records = missing_records + 1
        break if  missing_records == limit
    	  puts "\" #{place.chapman_code}\",\" #{place.place_name}\", unapproved place name" 
        message_file.puts   "\" #{place.chapman_code}\",\" #{place.place_name}\", unapproved place name" 
       
      end # my entry if
    end #place
    puts "There were #{missing_records} unapproved place_names in #{number} processed records"
    
  end
end