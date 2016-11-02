desc "Check freereg1_csv_file locations records are correct, setting fix to fix will correct it"
require 'chapman_code'
require "check_search_record"
require "check_freereg1_csv_file"

task :check_physical_file_not_processed_exist,[:limit,:fix] => :environment do |t, args|
  fix = true if args.fix == "fix"
  limit = args.limit
  file_for_warning_messages = "log/physical_file_report.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
  message_file = File.new(file_for_warning_messages, "w")
  limit = limit.to_i
  puts "Checking #{limit} physical documents not processed exist with #{fix}"
  message_file.puts "Checking #{limit} physical documents not processed exist with #{fix}"
  file_number = 0
  incorrect_files = 0
  files = PhysicalFile.count
  p "Total files: #{files}"
  start = Time.now
  PhysicalFile.uploaded_into_base.not_processed.not_waiting.all.order_by(base_uploaded_date: -1, userid: 1).no_timeout.each do |physical_file|
    file_number = file_number + 1
    break if file_number == limit
    file_count = Freereg1CsvFile.userid(physical_file.userid).file_name(physical_file.file_name).count
    physical_file_count = PhysicalFile.userid(physical_file.userid).file_name(physical_file.file_name).count
    place_ok = file_count == 1 && physical_file_count == 1
    if !place_ok
      incorrect_files = incorrect_files + 1
      message_file.puts "Userid ,#{physical_file.userid},#{physical_file.file_name}, #{file_count}, #{physical_file_count}"
      p "Userid ,#{physical_file.userid},#{physical_file.file_name}, #{file_count}, #{physical_file_count}"
      if fix
        physical_file.destroy if file_count == 0
        message_file.puts "Physical File Entry for Userid ,#{physical_file.userid},#{physical_file.file_name}"
      end
    else
      # p "Userid ,#{physical_file.userid},#{physical_file.file_name} was OK"
      #message_file.puts my_entry
    end
  end
  puts "checked #{file_number} places there were #{incorrect_files} incorrect places "
  message_file.close
end
