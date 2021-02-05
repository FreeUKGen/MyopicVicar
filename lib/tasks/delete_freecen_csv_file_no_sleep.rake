task :delete_freecen_csv_file_no_sleep,[:limit] => [:environment] do |t, args|
  file_for_warning_messages = "#{Rails.root}/log/delete_list_freecen_processing.txt"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  output_file = File.new(file_for_warning_messages, "a")
  input_file = Rails.root.join(Rails.application.config.delete_list)
  delete_files = []
  int = 0
  output_file.puts "Starting entry deletes at #{Time.now}"
  p "Starting entry deletes at #{Time.now}"
  if File.exist?(input_file)
    File.foreach(input_file) do |line|
      delete_files[int] = line
      int = int + 1
    end

    delete_files = delete_files.uniq
    output_file.puts delete_files
    start = Time.now
    total_records = 0
    files = 0
    sleep_time_twenty = 20*(Rails.application.config.sleep.to_f).to_f
    sleep_time_one_hundred = 100*(Rails.application.config.sleep.to_f).to_f

    delete_files.each  do |line|
      files = files + 1
      break if files == args.limit.to_i

      parts = line.split(",")
      line = line.chomp
      p " Starting #{files}  #{parts[0]},#{parts[1]},#{parts[2]}"
      record_number = 0
      if  FreecenCsvEntry.where(:freecen_csv_file_id => parts[0]).exists?
        FreecenCsvEntry.where(:freecen_csv_file_id => parts[0]).no_timeout.each do |entry|
          record_number = record_number + 1
          output_file.puts "#{entry.record_number},#{entry.civil_parish}, #{entry.enumeration_district},#{entry.piece_number}, #{entry.where_census_taken}" if record_number == 1
          entry.destroy
        end
        output_file.puts "#{record_number} records deleted for #{line}"
        puts "#{record_number} records deleted for #{line}"
        total_records = total_records + record_number
      else
        p "no records for that file id"
        output_file.puts "no records for that file id"
      end
    end
    File.truncate(input_file, 0)
    p " #{total_records} records deleted"
    output_file.puts " #{total_records} records deleted"
    elapse = Time.now - start
    output_file.puts elapse
  else
    output_file.puts "No input file"
    puts "No input file"
  end

  output_file.close
  p "finished"
end
