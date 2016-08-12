class UpdatePlaceUcf
  def self.process(limit)
    file_for_warning_messages = "log/place_ucf_update.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
    message_file = File.new(file_for_warning_messages, "w")
    p "Started a place ucf update for #{limit} files "
    message_file.puts  "Started a place ucf update for #{limit} files "
    n = 0
    software_version = SoftwareVersion.control.first
    version = software_version.version
    search_version  = software_version.last_search_record_version
    records = 0
    updated_records = 0
    time_start = Time.new
    Place.all.no_timeout.each do |place|
      place.ucf_list = []
      n = n + 1
      break if n == limit.to_i
      recs = place.search_records.count
      message_file.puts "#{place.place_name}/#{recs}"
      p "#{place.place_name}/#{recs}"
      records = records + recs
      if recs > 1


      else
        message_file.puts "No search records"
      end
    end
    time_end = Time.new
    process_time = (time_end - time_start)
    rate = process_time* 1000/ records
    message_file.puts "Processed #{records} records of which #{updated_records} were updated, #{created_records} created, #{digest_added} digests added, #{no_update} records changed in #{process_time} seconds at a rate of #{rate} ms/record"
    p "Processed #{records} records of which #{updated_records} were updated, #{created_records} created, #{digest_added} digests added, #{no_update} records changed in #{process_time} seconds at a rate of #{rate} ms/record"
  end
end
