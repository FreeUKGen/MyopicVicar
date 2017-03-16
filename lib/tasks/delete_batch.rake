task :delete_batch,[:batch] => [:environment] do |t, args|
  file_for_warning_messages = "#{Rails.root}/log/delete_batch_processing.txt"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  output_file = File.new(file_for_warning_messages, "a")
  int = 0
  output_file.puts "Starting entry deletes at #{Time.now}"


  p "Starting entry deletes at #{Time.now}"

  record_number = 0
  batch = Freereg1CsvFile.id(args.batch).first
  if batch.present?
    output_file.puts " #{batch.place},#{batch.church_name}, #{batch.register_type}, #{batch.record_type}"
    p " #{batch.place},#{batch.church_name}, #{batch.register_type}, #{batch.record_type}"
    Freereg1CsvEntry.where(:freereg1_csv_file_id => args.batch).no_timeout.each do |entry|
      record_number = record_number + 1
      entry.destroy
    end
    batch.delete
    output_file.puts "#{record_number} records deleted "
    puts "#{record_number} records deleted "
  else
    puts "#{args.batch} batch missing "
  end
  output_file.close
  p "finished"
end
