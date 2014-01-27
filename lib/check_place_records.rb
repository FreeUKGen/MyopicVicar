class CheckPlaceRecords


 
require 'chapman_code'

require "#{Rails.root}/app/models/place"
require "#{Rails.root}/app/models/master_place_name"

include Mongoid::Document
 


 
  def initialize
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    
  end

  def self.process(type)
  	file_for_warning_messages = "#{Rails.root}/log/places_in_gazetter.csv"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
    output_file = File.new(file_for_warning_messages, "w")
  	
    freereg1_csv_file = CheckPlaceRecords.new
  	missing_search_record = Array.new
  	
  	puts "Checking documents for missing Places for F2 in the place Gazetteer records collection"
  	record_number = 0
  	missing_records = 0
  	
  	places = Place.all
    places.each do |p|
  	  record_number = record_number + 1
  	  my_place = p.place_name.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase
      my_chapman = p.chapman_code   
       
      my_search_record = MasterPlaceName.where(:chapman_code => my_chapman,:modified_place_name => my_place ).first
      
      unless my_search_record.nil? 
      	  csv_string = [my_chapman, my_place, my_search_record.latitude, my_search_record.longitude].to_csv
          output_file.puts  csv_string
          
      else
      	csv_string = [my_chapman, my_place].to_csv
          output_file.puts  csv_string
          missing_records = missing_records + 1  
      end
    end  
    output_file.close 
    puts "checked #{record_number} entries there were #{missing_records} missing search records"
   
  end
end