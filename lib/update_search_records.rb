class UpdateSearchRecords
  def self.process(limit)
    file_for_warning_messages = "log/search_record_digest.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
    message_file = File.new(file_for_warning_messages, "w")
    p "Started a search_record update for #{limit} files"
    message_file.puts  "Started a search_record update for #{limit} files"
    n = 0
    software_version = SoftwareVersion.control.first
    version = software_version.version
    search_version  = software_version.last_search_record_version
    records = 0
    updated_records = 0
    created_records = 0
    time_start = Time.new
    Freereg1CsvFile.all.no_timeout.each do |file|
      n = n + 1
      break if n == limit.to_i
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
            	result = SearchRecord.update_create_search_record(entry,search_version,place.id)
            	updated_records = updated_records + 1 if result == "updated"
            	created_records = created_records + 1 if result == "created"
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
    message_file.puts "Processed #{records} records of which #{updated_records} were updated and #{created_records} created in #{process_time} seconds at a rate of #{rate} ms/record"
    p "Processed #{records} records of which #{updated_records} were updated and #{created_records} created in #{process_time} seconds at a rate of #{rate} ms/record"
  end
end
