task :delete_file,[:limit] => [:environment] do |t, args|
  Mongoid.load!("#{Rails.root}/config/mongoid.yml")
  file_for_warning_messages = "#{Rails.root}/log/delete_list_processing.txt"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  output_file = File.new(file_for_warning_messages, "a")
  input_file = Rails.application.config.delete_list
  delete_files = Array.new
  int = 0
  output_file.puts "Starting entry deletes at #{Time.now}"
  if File.exist?(input_file)
    File.foreach(input_file) do |line|
      delete_files[int] = line
      int = int + 1
    end
    File.truncate(input_file,0)
    delete_files = delete_files.uniq
    output_file.puts delete_files
    start = Time.now
    total_records = 0
    files = 0
    sleep_time_twenty = 20*(Rails.application.config.sleep.to_f).to_f
    sleep_time_one_hundred = 100*(Rails.application.config.sleep.to_f).to_f
    p "starting"
    delete_files.each  do |line|
      files = files + 1
      break if files == args.limit.to_i
      parts = line.split(",")
      line = line.chomp
      p " Starting #{files}  #{parts[0]},#{parts[1]},#{parts[2]}"
      record_number = 0
      if  Freereg1CsvEntry.where(:freereg1_csv_file_id => parts[0]).exists?
        Freereg1CsvEntry.where(:freereg1_csv_file_id => parts[0]).no_timeout.each do |entry|
          record_number = record_number + 1
          output_file.puts "#{entry.line_id},#{entry.county}, #{entry.place},#{entry.church_name}, #{entry.register_type}, #{entry.record_type}" if record_number == 1
          entry.destroy
          sleep(Rails.application.config.sleep.to_f)
        end
        output_file.puts "#{record_number} records deleted for #{line}"
        puts "#{record_number} records deleted for #{line}"
        total_records = total_records + record_number
        sleep(sleep_time_twenty)
      else
        p "no records for that file id"
        output_file.puts "no records for that file id"
      end
    end
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
