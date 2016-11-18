desc "Check freereg1_csv_file locations records are correct, setting fix to fix will correct it"
require 'chapman_code'
require "check_search_record"
require "check_freereg1_csv_file"

task :check_search_records,[:limit,:fix,:file] => :environment do |t, args|
  args.fix == "fix" ? fix = true : fix = false
  args.file == 'all' ? file_selection = false : file_selection = true
  limit = args.limit
  file_for_warning_messages = "log/check_search_records.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
  message_file = File.new(file_for_warning_messages, "w")
  limit = limit.to_i
  puts "Checking #{limit} documents for incorrect search records in the list of files #{args.file} with #{fix}"
  message_file.puts "Checking #{limit} documents for incorrect search records in the list of files #{args.file} with #{fix}"
  file_number = 0
  processing = 0
  number_processed = 0
  duplicate_search_records = 0
  missing_search_record = 0
  start = Time.now
  last_file_name = "old"
  software_version = SoftwareVersion.control.first
  version = software_version.version unless software_version.nil?
  search_version  = software_version.last_search_record_version if software_version.present? && software_version.last_search_record_version.present?
  search_version = 1 if search_version.blank?
  p search_version
  if file_selection
    input_file = File.join( Rails.root,'tmp',args.file)
    delete_files = Array.new
    int = 0
    new_line = Array.new
    File.foreach(input_file) do |line|
      new_line = line.split('/')
      delete_files[int] = new_line
      int = int + 1
    end
    files = delete_files.length
    message_file.puts "Total files: #{files}"
    p "Total files: #{files}"
    entries = 0
    delete_files.each do |delete_file|
      my_file = Freereg1CsvFile.userid(delete_file[0]).file_name(delete_file[1]).first
      if my_file.present?
        processing = processing + 1
        number_processed = number_processed + 1
        file_number = file_number + 1
        break if file_number == limit
        file_name = my_file.file_name
        owner = my_file.userid
        my_file.freereg1_csv_entries.no_timeout.each do |entry|
          entries = entries + 1
          record = SearchRecord.where(:freereg1_csv_entry_id => entry.id).count
          if record == 0
            p "missing entry"
             missing_search_record = missing_search_record + 1
            file = entry.entry.freereg1_csv_file
            if file.present?
              register = file.register if file.present?
              church = register.church if register.present?
              place = church.place if church.present?
              missing_search_record = missing_search_record + 1
              result = SearchRecord.create_search_record(entry,search_version,place.id) if fix && place.present?
              message_file.puts " #{file.userid}, #{file.file_name},missing search records" unless last_file_name == file_name || place.blank?
              last_file_name = file_name unless last_file_name == file_name || place.blank?
            else
              message_file.puts  "#{entry.id},#{entry.line_id},missing file as well as search records"
              entry.destroy if fix
            end
          end
          if record == 2
            duplicate_search_records = duplicate_search_records + 1
            record = SearchRecord.where(:freereg1_csv_entry_id => entry.id).first
            record.destroy if fix
          end
          if processing == 10
            processed_time = Time.now
            processing_time = (processed_time - start)*1000/entries
            message_file.puts "#{entries} entries processed at a rate of #{processing_time} ms/entry #{missing_search_record} missing records and #{duplicate_search_records } duplicates"
            p  "#{entries} entries processed at a rate of #{processing_time} ms/entry #{missing_search_record} missing records and #{duplicate_search_records } duplicates"
            processing = 0
          end
        end
      end
    end
  else
    files = Freereg1CsvEntry.count
    p "Total entries: #{files}"
    entries = 0    
     
        file_name = ""
        owner = ""
        Freereg1CsvEntry.no_timeout.each do |entry|
          processing = processing + 1
          number_processed = number_processed + 1  
          entries = entries + 1
          break if entries == limit
          record = SearchRecord.where(:freereg1_csv_entry_id => entry.id).count
          if record == 0
            p "missing search record for #{entry.id} at #{entries}"
            missing_search_record = missing_search_record + 1
            file = entry.freereg1_csv_file
            if file.present?
              register = file.register if file.present?
              church = register.church if register.present?
              place = church.place if church.present?     
              result = SearchRecord.create_search_record(entry,search_version,place.id) if fix && place.present?
              message_file.puts " #{file.userid}, #{file.file_name},missing search records" unless  file.id unless last_file_name == file.id || place.blank?
              last_file_name = file.id unless last_file_name == file.id || place.blank?
              sleep_time = (Rails.application.config.sleep.to_f).to_f
              sleep(sleep_time) if fix
            else
              message_file.puts  "#{entry.id},#{entry.line_id},missing file as well as search records"
              entry.destroy if fix
            end
          end
          if record == 2
            duplicate_search_records = duplicate_search_records + 1
            record = SearchRecord.where(:freereg1_csv_entry_id => entry.id).first
            record.destroy if fix
            message_file.puts  "#{entry.id},#{entry.line_id},duplicate search record"
            sleep_time = (Rails.application.config.sleep.to_f).to_f
            sleep(sleep_time) if fix
          end
          if processing == 10000
            processed_time = Time.now
            processing_time = (processed_time - start)*1000/entries
             message_file.puts "#{entries} entries processed at a rate of #{processing_time} ms/entry #{missing_search_record} missing records and #{duplicate_search_records } duplicates"
            p  "#{entries} entries processed at a rate of #{processing_time} ms/entry #{missing_search_record} missing records and #{duplicate_search_records } duplicates"
            processing = 0
          end
        end
  end
   message_file.puts "checked  #{entries} entries there were #{missing_search_record} missing records and #{duplicate_search_records } duplicates"
  p "checked  #{entries} entries there were #{missing_search_record} missing records and #{duplicate_search_records } duplicates"
  message_file.close
end
