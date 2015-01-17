class MissingPlaceFields



  require 'chapman_code'
  require 'church'
  require 'register'
  require 'freereg1_csv_file'
  require 'freereg1_csv_entry'

  require "place"
  include Mongoid::Document

  def self.process(limit)

    file_for_warning_messages = "log/missing_place_fields.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
    message_file = File.new(file_for_warning_messages, "w")
    limit = limit.to_i
    puts "checking places for missing county fields in the place collection"
    message_file.puts "Place Name,Chapman Code,County,Original Country,Country,Original Country"
    record_number = 0
    number = Place.count
    Place.all.each do |my_entry|
      if my_entry.county.nil? && my_entry.disabled == 'false' && my_entry.error_flag != "Place name is not approved"
        record_number = record_number + 1
        message_file.puts "\" #{my_entry.place_name}\", #{my_entry.chapman_code}, #{my_entry.county}, #{my_entry.original_county},  no location"
        county = ChapmanCode.name_from_code(my_entry.chapman_code)
        #if my_entry.update_attributes(:county => county)
        #  p "Error updating \" #{my_entry.place_name}\""
        # end
      end #place

    end
    puts "There were #{record_number} missing locations in #{number} places searched"
  end
end
