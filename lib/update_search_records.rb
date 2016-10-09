class UpdateSearchRecords
  def self.process(limit,record_type,search_version)
    file_for_warning_messages = "log/search_record_digest.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
    message_file = File.new(file_for_warning_messages, "a")

    unless RecordType.all_types.include?(record_type)
      p "Invalid record type #{record_type} it must be one of#{RecordType.all_types}"
      return
    end
    software_version = SoftwareVersion.control.first
    version = software_version.version unless software_version.nil?
    search_version  = software_version.last_search_record_version if search_version.blank? && software_version.last_search_record_version.present?
    search_version = 1 if search_version.blank?
    p "Started a search_record update for #{limit} files for #{record_type} and #{search_version} with pause of #{Rails.application.config.emmendation_sleep.to_f}"
    message_file.puts  "Started a search_record update for #{limit} files for #{record_type} and #{search_version}"
    records = 0
    updated_records = 0
    digest_added = 0
    no_update = 0
    created_records = 0
    files_bypassed = 0
    n = 0
    time_start = Time.new
    p "There are #{Freereg1CsvFile.record_type(record_type).count} files to be processed"
    message_file.puts "There are #{Freereg1CsvFile.record_type(record_type).count} files to be processed"
    Freereg1CsvFile.record_type(record_type).all.no_timeout.each do |file|
      n = n + 1
      break if n == limit.to_i
      #p file.search_record_version

      if file.search_record_version.blank? || file.search_record_version < search_version
        register = file.register
        church = register.church if register.present?
        place = church.place if church.present?
        if place.present?
          recs = file.records.to_i

          message_file.puts "#{file.userid}/#{file.file_name}/#{recs}"
          p "#{file.userid}/#{file.file_name}/#{recs}"
          p file.search_record_version
          records = records + recs
          file_records_update = 0
          file_records_not_updated = 0
          file_digest_added = 0
          file_created_records = 0
          if file.freereg1_csv_entries.count >= 1
            Freereg1CsvEntry.where(:freereg1_csv_file_id => file.id).all.no_timeout.each do |entry|
              result = SearchRecord.update_create_search_record(entry,search_version,place.id)
              #p result
              sleep(Rails.application.config.emmendation_sleep.to_f) if result == "updated" ||  result == "created"
              updated_records = updated_records + 1 if result == "updated"
              file_records_update = file_records_update + 1 if result == "updated"
              file_records_not_updated = file_records_not_updated + 1 if result == "no update"
              file_created_records = file_created_records + 1 if result == "created"
              file_digest_added = file_digest_added + 1 if result == "digest_added"
              no_update = no_update + 1 if result == "no update"
            end
            created_records = created_records + file_created_records
            digest_added = digest_added + file_digest_added
          else
            p "No entries"
            message_file.puts "No entries"
          end
          process_time = (Time.new - time_start)
          rate = process_time* 1000/ records
          message_file.puts "#{file.userid}/#{file.file_name}/#{recs}/#{file_created_records}/#{file_records_update}/#{file_records_not_updated} and #{n} files processed (#{files_bypassed} files bypassed) with #{records}  records total, #{created_records} created, #{updated_records} updated and #{no_update} unchanged todate at rate #{rate}"
          p "#{file.userid}/#{file.file_name}/#{recs}/#{file_created_records}/#{file_records_update}/#{file_records_not_updated} and #{n} files processed (#{files_bypassed} files bypassed) with #{records} records total, #{created_records} created, #{updated_records} updated and #{no_update} unchanged todate at rate #{rate}"
          file.update_attributes(:software_version => version, :search_record_version => search_version)
          sleep(20*(Rails.application.config.emmendation_sleep.to_f))
        else
          p "No place #{file.userid}/#{file.file_name}"
          message_file.puts "No place"
        end
      else
        p "bypassed #{file.search_record_version }"
        files_bypassed = files_bypassed + 1
      end
    end
    time_end = Time.new
    process_time = (time_end - time_start)
    rate = process_time* 1000/ records
    message_file.puts "Processed #{n} files, bypassed #{files_bypassed}. #{records} records of which #{updated_records} were updated, #{created_records} created, #{digest_added} digests added, #{no_update} records unchanged in #{process_time} seconds at a rate of #{rate} ms/record"
    p "Processed #{n} files, bypassed #{files_bypassed}.  #{records} records of which #{updated_records} were updated, #{created_records} created, #{digest_added} digests added, #{no_update} records unchanged in #{process_time} seconds at a rate of #{rate} ms/record"
  end
end
