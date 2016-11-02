desc "Check freereg1_csv_file locations records are correct, setting fix to fix will correct it"
require 'chapman_code'
require "check_search_record"
require "check_freereg1_csv_file"

task :check_search_records,[:limit,:fix,:file] => :environment do |t, args|
  args.fix == "fix" ? fix = true : fix = false
  input_file = File.join( Rails.root,'tmp',args.file)
  delete_files = Array.new
  int = 0
  new_line = Array.new
  File.foreach(input_file) do |line|
    new_line = line.split('/')
    delete_files[int] = new_line
    int = int + 1
  end
  limit = args.limit
  file_for_warning_messages = "log/check_search_records.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
  message_file = File.new(file_for_warning_messages, "w")
  limit = limit.to_i
  puts "Checking #{limit} documents for incorrect search records in the list of files #{input_file} with #{fix}"
  message_file.puts "Checking #{limit} documents for incorrect search records in the list of files #{input_file} with #{fix}"
  file_number = 0
  processing = 0
  number_processed = 0
  duplicate_search_records = 0
  missing_search_record = 0
  files = delete_files.length
  p "Total files: #{files}"
  entries = 0
  start = Time.now
  last_file_name = "old"
  delete_files.each do |delete_file|
    my_file = Freereg1CsvFile.userid(delete_file[0]).file_name(delete_file[1]).first
    if my_file.present?
      processing = processing + 1
      number_processed = number_processed + 1
      file_number = file_number + 1
      break if file_number == limit
      break if file_number == files
      file_name = my_file.file_name
      owner = my_file.userid
      my_file.freereg1_csv_entries.each do |entry|
        entries = entries + 1
        record = SearchRecord.where(:freereg1_csv_entry_id => entry.id).count
        if record == 0
          missing_search_record = missing_search_record + 1
          message_file.puts " #{owner}, #{file_name},missing search records" unless last_file_name == file_name
          last_file_name = file_name unless last_file_name == file_name
        end
        if record == 2
          duplicate_search_records = duplicate_search_records + 1
          record = SearchRecord.where(:freereg1_csv_entry_id => entry.id).first
          record.destroy if fix
        end
        if processing == 10
          processed_time = Time.now
          processing_time = (processed_time - start)*1000/entries
          p  "#{entries} entries processed at a rate of #{processing_time} ms/entry #{missing_search_record} missing records and #{duplicate_search_records } duplicates"
          processing = 0
        end
      end
    end
  end
  puts "checked #{file_number} files there were #{missing_search_record} missing records and #{duplicate_search_records } duplicates"
  message_file.close
end
