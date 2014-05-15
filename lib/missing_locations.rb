class MissingLocations


 
require 'chapman_code'
require 'church'
require 'register'
require 'freereg1_csv_file'
require 'freereg1_csv_entry'

require "place"
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
    message_file.puts "UserID,Place Name,County,Church Name,Register Name,File Name,Entries"
  	record_number = 0
  	missing_records = 0
  	process_records = 0
    number = Place.count

    places = Place.all

  	places.each do |my_entry|
      if my_entry.master_place_lat.nil? && my_entry.master_place_lon.nil? 
  	  record_number = record_number + 1
  	  puts "\" #{my_entry.place_name}\", #{my_entry.chapman_code}, no location" 
        churches = Church.where(:place_id => my_entry.id).all
         churches.each do |church|
          registers = Register.where(:church_id => church.id).all
            registers.each do |register|
              files = Freereg1CsvFile.where(:register_id => register.id).all
                files.each do |file|
                  entries = Freereg1CsvEntry.where(:freereg1_csv_file_id => file.id).count
                  message_file.puts "#{file.userid},\" #{my_entry.place_name}\", #{my_entry.chapman_code},\"#{church.church_name}\",\"#{register.alternate_register_name}\",#{file.file_name},#{entries}\n"
                end #file
            end #register
        end #church
       end # my entry if
      end #place
    puts "There were #{record_number} missing locations"
    
  end
end