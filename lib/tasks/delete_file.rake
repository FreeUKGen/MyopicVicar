task :delete_file, [:batch, :userid] => [:environment] do |t, args|
  file_for_warning_messages = "#{Rails.root}/log/delete_batch_processing.txt"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  output_file = File.new(file_for_warning_messages, "w")
  p "Starting file #{args.batch} delete for #{args.userid} at #{Time.now}"
  output_file.puts "Starting file #{args.batch} delete for #{args.userid} at #{Time.now}"
  number = 0
  batches = Freereg1CsvFile.file_name(args.batch).userid(args.userid).all
  batches.each do |batch|
    number = number + 1
    record_number = 0
    if batch.present?
      p " #{batch.place},#{batch.church_name}, #{batch.register_type}, #{batch.record_type} being destroyed"
      output_file.puts " #{batch.place},#{batch.church_name}, #{batch.register_type}, #{batch.record_type} being destroyed"
      Freereg1CsvEntry.freereg1_csv_file(batch.id).no_timeout.each do |entry|
        record_number = record_number + 1
        entry.destroy
      end
      p "#{record_number} records deleted "
      output_file.puts "#{record_number} records deleted "
    else
      p "#{args.batch} file for #{args.userid} missing "
      output_file.puts "#{args.batch} file for #{args.userid} missing "
    end
    batch.delete
    p 'Batch deleted'
    output_file.puts 'Batch deleted'
  end
  p "All #{number} batches deleted"
  output_file.puts "All #{number} batches deleted"
  physical_file = PhysicalFile.file_name(args.batch).userid(args.userid).first
  if physical_file.present?
    p 'physical file exists and destroyed'
    output_file.puts 'physical file exists and destroyed'
    physical_file.destroy
  else
    p 'No physical file exists'
    output_file.puts 'No physical file exists'
  end
  p "finished"
  output_file.puts "finished"
  output_file.close
end
