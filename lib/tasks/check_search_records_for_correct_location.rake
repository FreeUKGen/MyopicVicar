desc "Check search record locations are correct, setting fix to fix will correct it"
  require 'chapman_code'
  require "check_search_record"
  require "check_freereg1_csv_file"
  task :check_search_records_for_correct_location,[:limit,:fix] => :environment do |t, args|
    fix = args.fix
    limit = args.limit
    file_for_warning_messages = "log/check_search_records_location_messages.log"
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
    ChapmanCode.keys.each do |county|
      records = SearchRecord.chapman_code(county).count
      if records >= 1
        p "Record was Error,#{county},has ,#{records}" 
        message_file.puts "Record was Error,#{county},has ,#{records}"
        if fix == "fix" 
          CheckSearchRecord.correct_county_instead_of_chapman(county) 
          p "Fixed Record was Error,#{county},has ,#{records}" 
          message_file.puts "Fixed Record was Error,#{county},has ,#{records}" 
        end
      end
    end
    p "Finished check of county rather than chapman"
    Freereg1CsvFile.no_timeout.each do |my_file|
      processing = processing + 1
      number_processed = number_processed + 1
      file_number = file_number + 1
      break if file_number == limit
      break if file_number == files
      record_ok = CheckSearchRecord.check_search_record_location_and_county(my_file) 
      if !record_ok[0]
        incorrect_records = incorrect_records + my_file.freereg1_csv_entries.count
        message_file.puts "Record,#{my_file.userid},#{my_file.file_name},has ,#{my_file.freereg1_csv_entries.count}, #{record_ok[1]}"
      end
      if processing == 100
        processed_time = Time.now
        processing_time = (processed_time - start)*1000/number_processed 
        p  "#{number_processed} processed at a rate of #{processing_time} ms/file"
        processing = 0 
      end
      if fix == "fix" &&  !record_ok[0]
        if record_ok[1] == "No register" || record_ok[1] == "No church" || record_ok[1] == "No place" || record_ok[1] == "No entries" || record_ok[1] == "No search record"
          message_file.puts "Unable to fix Records,#{my_file.userid}, #{my_file.file_name},  #{record_ok[1]},unable to fix"
          p "Unable to fix Records,#{my_file.userid}, #{my_file.file_name}, #{record_ok[1]}"
        else 
          fixed = CheckSearchRecord.correct_record_location_fields(my_file)
          fixed_records = fixed_records + fixed
          message_file.puts "Fixed,#{my_file.userid}, #{my_file.file_name}, #{fixed},entries and records"
          p "Fixed Records,#{my_file.userid}, #{my_file.file_name},#{fixed},entries and records"
        end
      end   
    end
    puts "checked #{file_number} files there were #{incorrect_files} incorrect files and #{incorrect_records} incorrect search records and #{fixed_records} were fixed"
    message_file.close 
end
