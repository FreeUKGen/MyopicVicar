task :extract_county_and_chapman_code,[:limit] => [:environment] do |t, args|
  file_for_warning_messages = "#{Rails.root}/log/county_chapman_codes.txt"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  output_file = File.new(file_for_warning_messages, "w")
  start = Time.now
  output_file.puts start
  record_number = 0
  errors = Array.new
  codes = ChapmanCode.merge_countries

  Freereg1CsvFile.no_timeout.each do |file|
      record_number = record_number + 1
      break if record_number == args.limit.to_i
      unless ChapmanCode::values.include?(file.county)
        output_file.puts "#{file.id},#{file.county}"
        file.update_attribute(:county,codes[file.county])
        output_file.puts "#{file.id},#{file.county}"
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
