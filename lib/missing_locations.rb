class MissingLocations


 
require 'chapman_code'


require "#{Rails.root}/app/models/place"
include Mongoid::Document
 


 
  def initialize
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    
  end

  def self.process(limit)
  	file_for_warning_messages = "log/check_locations_messages.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
    message_file = File.new(file_for_warning_messages, "w")
  	limit = limit.to_i
    puts "checking #{limit} documents for missing locations in the place collection"
  	record_number = 0
  	missing_records = 0
  	process_records = 0
    number = Place.count

    places = Place.all

  	places.each do |my_entry|
      if my_entry.master_place_lat.nil?
  	  record_number = record_number + 1
  	  message_file.puts "\" #{my_entry.place_name}\", #{my_entry.chapman_code}, no location" 
      end
      end
    puts "There were #{record_number} missing locations"
    
  end
end