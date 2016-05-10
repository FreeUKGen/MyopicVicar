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
  p version
  p search_version
 
  records = 0
  time_start = Time.new
  Freereg1CsvFile.all.no_timeout.each do |file|
    array_of_digests = Array.new
    n = n + 1
    break if n == 100
    recs = file.freereg1_csv_entries.count
    p "#{file.userid}/#{file.file_name}/#{recs}"
    records = records + recs
    file.update_attributes(:software_version => version, :search_record_version => search_version) unless software_version == file.software_version && search_version == file.search_record_version
    if file.freereg1_csv_entries.count > 1
      Freereg1CsvEntry.where(:freereg1_csv_file_id => file.id).all.no_timeout.each do |entry|
        duplicate = false
        search_record = entry.search_record
        if search_record.present? && search_record.search_record_version != search_version
          new_digest = search_record.cal_digest
          search_record.update_attributes(:search_record_version => search_version, :digest => new_digest)
          duplicate = true if array_of_digests.include?(new_digest)
          array_of_digests << new_digest unless duplicate
          p "duplicate search record digest for #{search_record.inspect} #{new_digest} in #{file.userid}/#{file.file_name}" if duplicate
        end 
      end 
    else
      p "No entries"
    end  
  end
  time_end = Time.new
  process_time = (time_end - time_start)
  rate = process_time* 1000/ records
  p "finished #{records} records in #{process_time} at a rate of #{rate}"
end
