namespace :freecen do

  desc 'FREECEN Add freecen2_place_id for birth_place to search_records'
  task :search_records_add_freecen2_place_of_birth_id, [:county, :limit, :fix] => [:environment] do |t, args|
    start_time = Time.now
    county = args.county.to_str
    limit = args.limit.to_i
    already_set = 0
    birth_place_empty = 0
    not_settable = 0
    records_updated = 0
    fixit = args.fix.to_str == 'Y'
    file_for_warning_messages = "log/search_records_add_freecen2_place_of_birth_id_#{county}_#{start_time.strftime('%Y%m%d%H%M')}.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
    message_file = File.new(file_for_warning_messages, 'w')
    info_message =  "Run parameters = #{county}, #{limit}, #{fixit}"
    p info_message
    message_file.puts info_message

    total_recs_to_process = SearchRecord.where(chapman_code: county).no_timeout.count
    info_message = "Total Records to Process for #{county} = #{total_recs_to_process}"
    p info_message
    message_file.puts info_message

    SearchRecord.where(chapman_code: county).no_timeout.each do |record|

      if record.freecen2_place_of_birth_id.present?
        already_set += 1
        next

      end

      if record.birth_chapman_code.blank? || record.birth_place.blank?
        birth_place_empty += 1
        next

      end

      valid_pob, place_id = Freecen2Place.valid_place(record.birth_chapman_code, record.birth_place)
      if valid_pob
        record.update_attributes(freecen2_place_of_birth: place_id) if fixit
        records_updated += 1
      else
        not_settable += 1
      end

      records = records_updated + not_settable
      if records == (records / 10000) * 10000
        time_diff = Time.now - start_time
        average = time_diff * 1000 / records
        info_message = "Average Process Time at #{records} records is #{average.round(2)} msecs per record"
        p info_message
        message_file.puts info_message
      end

      break if records_updated >= limit
    end

    time_diff = Time.now - start_time
    average = time_diff * 1000 / (already_set + birth_place_empty + not_settable + records_updated)

    info_message = "Records already set #{already_set}"
    p info_message
    message_file.puts info_message
    info_message = "Records birth place empty #{birth_place_empty}"
    p info_message
    message_file.puts info_message
    info_message = "Records not settable #{not_settable}"
    p info_message
    message_file.puts info_message
    info_message = fixit ? "Records updated #{records_updated}" : "Records to update #{records_updated}"
    p info_message
    message_file.puts info_message
    info_message = "Final Records Processed  = #{already_set + birth_place_empty + not_settable + records_updated}, Average Process Time = #{average.round(2)} msecs per record"
    p info_message
    end_time = Time.now
    run_time = ((end_time - start_time).to_f / 60).round(2).to_s
    info_message = "Run time = #{run_time} mins"
    p info_message
    message_file.puts info_message
  end
end
