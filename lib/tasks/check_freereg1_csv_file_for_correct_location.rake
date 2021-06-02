desc "Check freereg1_csv_file locations records are correct, setting fix to fix will correct it"
require 'chapman_code'
require "check_search_record"
require "check_freereg1_csv_file"

task :check_freereg1_csv_file_for_correct_location, [:limit, :fix] => :environment do |t, args|
  fix = true if args.fix == "fix"
  limit = args.limit
  file_for_warning_messages = "log/check_freereg1_csv_file_messages.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
  message_file = File.new(file_for_warning_messages, "w")
  limit = limit.to_i
  puts "Checking #{limit} documents for incorrect location in the freereg1_csv_file collection with #{fix}"
  message_file.puts "Checking #{limit} documents for incorrect location in the freereg1_csv_file collection with #{fix}"
  file_number = 0
  incorrect_files = 0
  incorrect_records = 0
  fixed_records = 0
  processing = 0
  number_processed = 0
  files = Freereg1CsvFile.count
  p "Total files: #{files}"
  start = Time.now
  Freereg1CsvFile.no_timeout.each do |my_file|
    processing = processing + 1
    number_processed = number_processed + 1
    file_number = file_number + 1
    break if file_number == limit
    break if file_number == files
    file_ok = CheckFreereg1CsvFile.check_county(my_file,fix)
    if !file_ok[0]
      incorrect_files = incorrect_files + 1
      message_file.puts "File, #{my_file.id}, #{my_file.userid}, #{my_file.file_name},#{my_file.county},#{my_file.place},#{my_file.church_name},#{my_file.register_type}, #{file_ok[1]}"
      #message_file.puts my_entry
    end
    if processing == 100
      processed_time = Time.now
      processing_time = (processed_time - start)*1000/number_processed
      p  "#{number_processed} processed at a rate of #{processing_time} ms/file"
      processing = 0
    end
  end
  puts "checked #{file_number} files there were #{incorrect_files} incorrect files "
  message_file.close
end
