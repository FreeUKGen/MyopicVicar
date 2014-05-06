class DatabaseContents


 
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

  def self.process(limit,type)

  	file_for_warning_messages = "log/check_locations_messages.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
    message_file = File.new(file_for_warning_messages, "w")
  	limit = limit.to_i
    puts "checking plsce/church/register content"
    message_file.puts "UserID,Place Name,County,Church Name,Register Name,File Name,Entries"
  	record_number = 0
  	missing_records = 0
  	process_records = 0
    number = Place.count

    places = Place.all

  	places.each do |my_entry|
      churches = Church.where(:place_id => my_entry.id).all
         churches.each do |church|
          registers = Register.where(:church_id => church.id).all
           
              registers.each do |register|
                 if type == "files"
                     files = Freereg1CsvFile.where(:register_id => register.id).all
                     files.each do |file|
                        entries = Freereg1CsvEntry.where(:freereg1_csv_file_id => file.id).count
                        message_file.puts "#{file.userid},\" #{my_entry.place_name}\", #{my_entry.chapman_code},\"#{church.church_name}\",\"#{register.alternate_register_name}\",#{file.file_name},#{entries}\n"
                     end #file
          
                 else
                  file = register.freereg1_csv_files[0]
                  message_file.puts "\" #{my_entry.place_name}\", #{my_entry.chapman_code},\"#{church.church_name}\",\"#{register.alternate_register_name}\"\n"
                 end
            end #register
        end #church

      end #place
   
    
  end
end