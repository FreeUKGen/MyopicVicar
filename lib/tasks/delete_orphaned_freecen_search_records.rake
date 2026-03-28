task :delete_orphaned_freecen_search_records,[:limit] => [:environment] do |t, args|
  Mongoid.load!("#{Rails.root}/config/mongoid.yml")

  start_time = Time.current
  output_file.puts "Starting Deletion of Freecen Ophaned Search records at #{start_time}"
  file_date = Time.current.strftime('%Y%m%d%H%M')
  file_for_log = "#{Rails.root}/log/delete_orphaned_freecen_search_records_#{file_date}.log"
  FileUtils.mkdir_p(File.dirname(file_for_log))
  output_file = File.new(file_for_log, 'w')
  file = File.join("#{Rails.root}/log/freecen_search_records_broken_csv_files_link.txt")
  input_file = File.open(file, 'r')
  message = "Starting Deletion of Freecen Ophaned Search records at #{start_time}"
  output_file.puts message
  p message
  message = '_id,chapman_code,record_type,freecen2_piece_id, freecen_csv_file_id, freecen_csv_entry_id'
  output_file.puts message

  total_recs = 0

  sleep = Rails.application.config.sleep.to_f
  sleep_time_twenty = 40*(Rails.application.config.sleep.to_f).to_f
  sleep_time_one_hundred = 100*(Rails.application.config.sleep.to_f).to_f
  sleep_time_two_thousand = 2000*(Rails.application.config.sleep.to_f).to_f
  sleep_time_ten_thousand = 10000*(Rails.application.config.sleep.to_f).to_f

  input_file.each_line  do |line|
    break if total_recs >= args.limit.to_i

    rec_id = line.chomp
    id = BSON::ObjectId(rec_id)
    search_rec = SearchRecords.where(:_id => id)
    if search_rec.exists?
      output_file.puts "#{search_rec._id},#{search_rec.chapman_code}, #{search_rec.record_type},#{search_rec.freecen2_piece_id}, #{search_rec.freecen_csv_file_id},#{search_rec.freecen_csv_entry_id}"
      # search_rec.destroy comment out for initial testing AEV
      sleep(sleep_time_twenty)
      message = "Search record with id #{line} deleted."
      output_file.puts message
      total_recs += 1
      # sleep(sleep_time_two_thousand) AEV
    else
      message = "No Search record with id #{line} not found."
      output_file.puts message
    end
  end
  message = "#{total_recs} records deleted"
  output_file.puts message
  p message
  end_time = Time.current
  run_time = end_time - start_time
  message = "Finished. Deleted: #{total_recs} Search records. Run Time = #{run_time.round(2)} secs"
  log_file.puts message
  p message
end
