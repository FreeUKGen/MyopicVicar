task :delete_orphaned_freecen_search_records,[:limit] => [:environment] do |t, args|
  Mongoid.load!("#{Rails.root}/config/mongoid.yml")

  start_time = Time.current
  file_date = Time.current.strftime('%Y%m%d%H%M')
  file_for_log = "#{Rails.root}/log/delete_orphaned_freecen_search_records_#{file_date}.log"
  FileUtils.mkdir_p(File.dirname(file_for_log))
  output_file = File.new(file_for_log, 'w')
  file = File.join("#{Rails.root}/log/freecen_search_records_broken_csv_files_link.txt")
  input_file = File.open(file, 'r')
  message = "Starting Deletion of Freecen Orphaned Search records at #{start_time}"
  output_file.puts message
  p message
  message = '_id,chapman_code,record_type,freecen2_piece_id, freecen_csv_file_id, freecen_csv_entry_id, message'
  output_file.puts message

  total_recs = 0
  del_recs = 0

  sleep_time = Rails.application.config.sleep.to_f
  sleep_time_twenty = 20*(Rails.application.config.sleep.to_f).to_f


  input_file.each_line  do |line|
    break if total_recs >= args.limit.to_i

    total_recs += 1
    rec_id = line.chomp
    id = BSON::ObjectId(rec_id)
    search_rec = SearchRecord.find(id: id)

    if search_rec.present?
      message = "#{search_rec.id},#{search_rec.chapman_code}, #{search_rec.record_type},#{search_rec.freecen2_piece_id}, #{search_rec.freecen_csv_file_id},#{search_rec.freecen_csv_entry_id},Deleted"
      output_file.puts message
      search_rec.destroy
      sleep(sleep_time)
      del_recs += 1
    else
      message = "#{rec_id},,,,,,Not Found ****"
      output_file.puts message
      p message
    end
  end

  end_time = Time.current
  run_time = end_time - start_time
  message = "Finished. Deleted: #{del_recs} Search records of #{total_recs} lines in input txt file. Run Time = #{run_time.round(2)} secs"
  output_file.puts message
  p message
end
