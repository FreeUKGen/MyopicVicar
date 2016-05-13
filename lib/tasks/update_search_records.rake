desc "Get a list of blanlk counties"
task :update_search_records => :environment do

  file_for_warning_messages = "log/search_record_digest.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
  message_file = File.new(file_for_warning_messages, "w")
  p "Started a search_record update and test"
  message_file.puts  "Started a search_record update and test"
  n = 0
  software_version = SoftwareVersion.control.first
  version = software_version.version
  search_version  = software_version.last_search_record_version
  records = 0
  time_start = Time.new
  Freereg1CsvFile.all.no_timeout.each do |file|
    n = n + 1
    break if n == 1000
    unless software_version == file.software_version && search_version == file.search_record_version
      register = file.register
      church = register.church if register.present?
      place = church.place if church.present?
      if place.present?
        recs = file.freereg1_csv_entries.count
        message_file.puts "#{file.userid}/#{file.file_name}/#{recs}"
        p "#{file.userid}/#{file.file_name}/#{recs}"
        records = records + recs        
        if file.freereg1_csv_entries.count > 1
          Freereg1CsvEntry.where(:freereg1_csv_file_id => file.id).all.no_timeout.each do |entry|
            search_record = entry.search_record
            if search_record.present?
              if search_record.search_record_version != search_version
                new_digest = search_record.cal_digest
                #p new_digest
                new_search_record = SearchRecord.new(Freereg1Translator.translate(entry.freereg1_csv_file, entry))
                new_search_record.freereg1_csv_entry = entry
                new_search_record.place = place
                #p new_search_record
                new_search_record.transform
                #p new_search_record
                brand_new_digest = new_search_record.cal_digest
                #p brand_new_digest
                if brand_new_digest == new_digest
                  search_record.search_record_version = search_version
                  search_record.digest = new_digest
                  search_record.save
                else
                  message_file.puts "Updating Search Record "
                  message_file.puts search_record.inspect
                  message_file.puts "Original Search Names"
                  message_file.puts search_record.search_names.inspect
                  search_record.search_record_version = search_version
                  search_record.digest = brand_new_digest
                  search_record.location_names = new_search_record.location_names unless search_record.location_names == new_search_record.location_names
                  search_record.search_soundex = new_search_record.search_soundex unless search_record.search_soundex == new_search_record.search_soundex
                  search_record.search_dates = new_search_record.search_dates unless search_record.search_dates == new_search_record.search_dates
                  original = {}
                  search_record.search_names.each { |row|  original[row._id] = row }
                  new_version = {}
                  new_search_record.search_names.each  { |row|  new_version[row._id] = row }
                  original_copy = original
                  original.delete_if {|key, value| new_version.has_value?(value)}
                  new_version.delete_if {|key, value| original_copy.has_value?(value)}
                  original.each_key {|key| search_record.search_names.delete(search_record.search_names.find(key))}
                  new_version.each_key {|key|  search_record.search_names << new_search_record.search_names.find(key)}
                  message_file.puts "Revised Search Names"
                  message_file.puts search_record.inspect
                  message_file.puts search_record.search_names.inspect
                end
                search_record.save
              end
            else
              message_file.puts "missing search record"
            end
          end
        end
        file.update_attributes(:software_version => version, :search_record_version => search_version) 
      else
        message_file.puts "No entries"
      end
    end
  end
  time_end = Time.new
  process_time = (time_end - time_start)
  rate = process_time* 1000/ records
  message_file.puts "finished #{records} records in #{process_time} at a rate of #{rate}"
  p "finished #{records} records in #{process_time} at a rate of #{rate}"
end
