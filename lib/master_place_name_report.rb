class MasterPlaceNameReport


 
require 'chapman_code'

include Mongoid::Document
 


 
  def initialize
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    
  end

  def self.process(limit)

  	file_for_messages = "log/master_place_name_report.log"
    FileUtils.mkdir_p(File.dirname(file_for_messages) )
    message_file = File.new(file_for_messages, "w")
  	limit = limit.to_i
 
    puts "Producing report of documents in the Master PlaceNames collection"
    message_file.puts "Country,County,Chapman,Place,Grid,Lat,Long,Source,Original Country,Original County, Original Chapman,Original Place,Original Grid,Original Lat, Original Long,Original Source,Reason for Change, Second Reason,Genuki, Disabled"
  	record_number = 0
  	missing_records = 0
  	process_records = 0
    number = MasterPlaceName.count

    places = MasterPlaceName.all

  	places.each do |my_entry|
      message_file.puts "\"#{my_entry.country}\",\" #{my_entry.county}\",\" #{my_entry.chapman_code}\",\"#{my_entry.place_name}\",\"#{my_entry.grid_reference}\",\" #{my_entry.latitude}\",\" #{my_entry.longitude}\",\"#{my_entry.source}\",\"#{my_entry.original_country}\",\" #{my_entry.original_county}\",\" #{my_entry.original_chapman_code}\",\"#{my_entry.original_place_name}\",\"#{my_entry.original_grid_reference}\",\" #{my_entry.original_latitude}\",\"#{my_entry.original_longitude}\",\"#{my_entry.original_source}\",\"#{my_entry.reason_for_change}\",\" #{my_entry.other_reason_for_change}\",\"#{my_entry.genuki_url}\",\" #{my_entry.disabled}\",\n" 
      end #place
  p "Finished #{number} records"
    
  end
end