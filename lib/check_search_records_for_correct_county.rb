class CheckSearchRecordsForCorrectCounty

  require 'chapman_code'
  require "freereg1_csv_file"
  require "freereg1_csv_entry"
  require "search_record"
  include Mongoid::Document

  def self.process(limit,fix)
    file_for_warning_messages = "log/check_search_records_messages.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
    message_file = File.new(file_for_warning_messages, "w")
    limit = limit.to_i
    puts "Checking #{limit} documents for incorrect county in the search records collection with #{fix}"
    message_file.puts "Checking #{limit} documents for incorrect county in the search records collection with #{fix}"
    file_number = 0
    incorrect_files = 0
    incorrect_records = 0
    fixed_records = 0
    processing = 0
    number_processed = 0 
    files = Freereg1CsvFile.count
    p "Total files: #{files}"
    start = Time.now
    files = Freereg1CsvFile.all
    files.each do |my_file|
      processing = processing + 1
      number_processed = number_processed + 1
      file_number = file_number + 1
      break if file_number == limit
      break if file_number == files
      file_ok = my_file.check_county
      if !file_ok[0]
        incorrect_files = incorrect_files + 1
        message_file.puts "File,#{my_file.userid}, #{my_file.file_name},#{my_file.county},#{my_file.place},#{my_file.church_name},#{my_file.register_type}, #{file_ok[1]}"
        #message_file.puts my_entry
      end
      
      if processing == 100
        processed_time = Time.now
        processing_time = (processed_time - start)*1000/number_processed 
        p  "#{number_processed} processed at a rate of #{processing_time} ms/file"
        processing = 0 
      end
      if fix == "fix" &&  !file_ok[0]
        if file_ok[1] == "No register" || file_ok[1] == "No church" || file_ok[1] == "No place" 
          message_file.puts "Unable to fix File,#{my_file.userid}, #{my_file.file_name}"
          p "Unable to fix File,#{my_file.userid}, #{my_file.file_name},#{file_ok[1]}"
        else 
          my_file.correct_file_location_fields
          message_file.puts "Fixed File,#{my_file.userid}, #{my_file.file_name}"
          p "Fixed File,#{my_file.userid}, #{my_file.file_name}"
        end
      end
      
    end
    puts "checked #{file_number} files there were #{incorrect_files} incorrect files and #{incorrect_records} incorrect search records and #{fixed_records} were fixed"
    message_file.close 
    return
  end

end
