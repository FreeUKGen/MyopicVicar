task :extract_orphans,[:limit] => [:environment] do |t, args|
  file_for_warning_messages = "#{Rails.root}/log/orphan_files.txt"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  output_file = File.new(file_for_warning_messages, "a")
  start = Time.now
  output_file.puts start
  record_number = 0
  errors = Array.new
  Freereg1CsvEntry.no_timeout.each do |entry|
    record_number = record_number + 1
    break if record_number == args.limit.to_i
    unless Freereg1CsvFile.where(:id => entry.freereg1_csv_file_id).exists?
      unless errors.include?(entry.freereg1_csv_file_id) 
        errors << entry.freereg1_csv_file_id 
        output_file.puts entry.freereg1_csv_file_id 
      end
    end
  end
  errors = errors.uniq
  record_number = errors.length
  puts " #{record_number} errors"
  puts errors
  output_file.puts " #{record_number} errors"  
  output_file.puts errors.inspect
  output_file.puts Time.now 
  elapse = Time.now - start
  output_file.puts elapse
  output_file.close
  p "finished"
end
