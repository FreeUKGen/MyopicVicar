desc "Check freereg1_csv_file locations records are correct, setting fix to fix will correct it"
require 'chapman_code'
require "check_search_record"
require "check_freereg1_csv_file"

task :check_place_country,[:limit,:fix] => :environment do |t, args|
  fix = true if args.fix == "fix"
  limit = args.limit
  file_for_warning_messages = "log/place_country_messages.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
  message_file = File.new(file_for_warning_messages, "w")
  limit = limit.to_i
  puts "Checking #{limit} documents for incorrect country in the place collection with #{fix}"
  message_file.puts "Checking #{limit} documents for incorrect country in the place collection with #{fix}"
  file_number = 0
  incorrect_files = 0
  incorrect_records = 0
  fixed_records = 0
  processing = 0
  number_processed = 0
  files = Place.count
  p "Total files: #{files}"
  start = Time.now
  Place.not_disabled.no_timeout.each do |place|
    processing = processing + 1
    number_processed = number_processed + 1
    file_number = file_number + 1
    break if file_number == limit
    break if file_number == files
    place_ok = place.check_place_country?
    if !place_ok
      incorrect_files = incorrect_files + 1
      message_file.puts "Place,#{place.place_name},#{place.county},#{place.country}}"
      if fix
        place.country = place.get_correct_place_country
        place.save
        message_file.puts "Place,#{place.place_name},#{place.county},#{place.country}, fixed"
      end
      #message_file.puts my_entry
    end
    if processing == 100
      processed_time = Time.now
      processing_time = (processed_time - start)*1000/number_processed
      p  "#{number_processed} processed at a rate of #{processing_time} ms/file"
      processing = 0
    end
  end
  puts "checked #{file_number} places there were #{incorrect_files} incorrect places "
  message_file.close
end
