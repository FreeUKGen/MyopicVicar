class UnapprovedAndNoData



  require 'chapman_code'
  require 'church'
  require 'register'
  require 'freereg1_csv_file'
  require 'freereg1_csv_entry'

  require "place"
  include Mongoid::Document

  def self.process(limit)

    file_for_warning_messages = "log/unapproved_and_no_data.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
    message_file = File.new(file_for_warning_messages, "w")
    limit = limit.to_i
    puts "checking places for unapproved and no churches present"
    message_file.puts "Place Name,Chapman Code,County,Original Country,Country,Original Country"
    record_number = 0
    number = Place.count
     Place.all.each do |my_entry|
      if my_entry.error_flag == "Place name is not approved" && my_entry.churches.count == 0 && !my_entry.data_present 
        record_number = record_number + 1
        message_file.puts "\" #{my_entry.place_name}\", #{my_entry.chapman_code}, #{my_entry.county}, #{my_entry.original_county},  no location"
        my_entry.delete
      end #place
     
    end
     puts "There were #{record_number} unapproved places with no churches in #{number} places"
     nember_end = Place.count
     p "Now #{nember_end} places"
  end
end
