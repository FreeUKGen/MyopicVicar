desc "Check freereg1_csv_file locations records are correct, setting fix to fix will correct it"
require 'chapman_code'
require "check_search_record"
require "check_freereg1_csv_file"

task :check_file_exists_for_processed_file,[:limit] => :environment do |t, args|
  limit = args.limit
  file_for_warning_messages = "log/file exists for processed file.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
  message_file = File.new(file_for_warning_messages, "w")
  limit = limit.to_i
  puts "Checking #{limit} files"
  message_file.puts "Checking #{limit} files"
  file_number = 0
  incorrect_files = 0
  files = Freereg1CsvFile.count
  p "Total files: #{files}"
  Freereg1CsvFile.no_timeout.each do |freereg1_csv_file|
    file_number = file_number + 1
    break if file_number == limit
    file_location = File.join(Rails.application.config.datafiles,freereg1_csv_file.userid,freereg1_csv_file.file_name)
    unless File.file?(file_location)
      incorrect_files = incorrect_files + 1
      physical_file = PhysicalFile.userid(freereg1_csv_file.userid).file_name(freereg1_csv_file.file_name).first
      if physical_file.present?
        message_file.puts "#{freereg1_csv_file.userid},#{freereg1_csv_file.file_name},#{physical_file.base_uploaded_date},#{physical_file.file_processed_date}"
        p "#{freereg1_csv_file.userid},#{freereg1_csv_file.file_name},#{physical_file.base_uploaded_date},#{physical_file.file_processed_date}"
      else
        message_file.puts "#{freereg1_csv_file.userid},#{freereg1_csv_file.file_name}"
        p "#{freereg1_csv_file.userid},#{freereg1_csv_file.file_name}"
      end 
    end  
  end
  puts "checked #{file_number} files there were #{incorrect_files} incorrect files "
  message_file.close
end
