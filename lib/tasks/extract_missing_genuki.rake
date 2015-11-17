task :extract_missing_genuki,[:limit] => [:environment] do |t, args|
  file_for_warning_messages = "#{Rails.root}/log/missing_location_links.txt"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  output_file = File.new(file_for_warning_messages, "w")
  start = Time.now
  output_file.puts start
  record_number = 0
  errors = 0
  Place.no_timeout.each do |place|
    record_number = record_number + 1
    break if record_number == args.limit.to_i
    if place.genuki_url.blank? && place.disabled == "false"
      errors = errors + 1
       output_file.puts ("#{place.id}, #{place.chapman_code}, #{place.place_name}")
    end
    
  end
  puts " #{errors} errors"
  
  output_file.puts " #{errors} errors"  
  
  output_file.puts Time.now 
  elapse = Time.now - start
  output_file.puts elapse
  output_file.close
  p "finished"
end
