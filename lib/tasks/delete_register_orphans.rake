task :delete_register_orphans,[:limit] => [:environment] do |t, args|
  Mongoid.load!("#{Rails.root}/config/mongoid.yml")
  file_for_warning_messages = "#{Rails.root}/log/register_orphan_files_processing.txt"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  output_file = File.new(file_for_warning_messages, "a")
  file = File.join("#{Rails.root}/log/register_orphan_files_list.txt")
  input_file = File.open(file,"r")
  start = Time.now
  output_file.puts start
  total_records = 0
  files = 0
  sleep = Rails.application.config.sleep.to_f
  sleep_time_twenty = 40*(Rails.application.config.sleep.to_f).to_f
  sleep_time_one_hundred = 100*(Rails.application.config.sleep.to_f).to_f
  sleep_time_two_thousand = 2000*(Rails.application.config.sleep.to_f).to_f
  sleep_time_ten_thousand = 10000*(Rails.application.config.sleep.to_f).to_f
  p "starting"
  input_file.each_line  do |line|
    p line
    files = files + 1
    break if files == args.limit.to_i
    line = line.chomp
    p " Starting #{files}  #{line}"
    record_number = 0
      Freereg1CsvEntry.where(:freereg1_csv_file_id => line).no_timeout.each do |entry|
        record_number = record_number + 1
        entry.destroy  
        sleep(sleep_time_twenty)  
      end
      output_file.puts "#{record_number} records deleted for #{line}"
      puts "#{record_number} records deleted for #{line}"
      total_records = total_records + record_number
      sleep(sleep_time_two_thousand )
  end
  p " #{total_records} records deleted"
  output_file.puts " #{total_records} records deleted"
  elapse = Time.now - start
  output_file.puts elapse
  output_file.close
  p "finished"
end
