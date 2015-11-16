task :extract_register_orphans,[:limit] => [:environment] do |t, args|
  file_for_warning_messages = "#{Rails.root}/log/register_orphan_files.txt"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  output_file = File.new(file_for_warning_messages, "a")
  start = Time.now
  output_file.puts start
  record_number = 0
  errors = Array.new
  Freereg1CsvFile.no_timeout.each do |bad_file|
    if bad_file.register_id.blank?
      record_number = record_number + 1
      break if record_number == args.limit.to_i
      errors << bad_file.id 
      output_file.puts bad_file.inspect
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
