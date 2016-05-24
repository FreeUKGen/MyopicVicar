task :physical_file_orphans,[:limit,:fix] => [:environment] do |t, args|
  file_for_warning_messages = "#{Rails.root}/log/physical_files.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  output_file = File.new(file_for_warning_messages, "a")
  start = Time.now
  output_file.puts start
  record_number = 0
  p "***************** Testing for unprocessed in change and #{args.fix}"
  output_file.puts  "Testing for unprocessed in change and #{args.fix}"
  PhysicalFile.not_waiting.not_processed.not_uploaded_into_base.uploaded_into_change.no_timeout.order_by(userid: 1).each do |file|
    record_number = record_number + 1
    break if record_number == args.limit.to_i
    file_location = File.join(Rails.application.config.datafiles,file.userid,file.file_name)
    if File.file?(file_location)
      output_file.puts  "#{file.userid},#{file.file_name},FR2 file present"
      p "#{file.userid},#{file.file_name},FR2 file present"
      FR2 = true
    else 
      output_file.puts "#{file.userid},#{file.file_name},FR2 not present"
      p "#{file.userid},#{file.file_name},FR2 not present"
      FR2 = false
    end
    file_location = File.join(Rails.application.config.datafiles_changeset,file.userid,file.file_name)
    if File.file?(file_location)
      output_file.puts  "#{file.userid},#{file.file_name},FR1 file present"
      p "#{file.userid},#{file.file_name},FR1 file present"
      FR1 = true
    else 
      output_file.puts "#{file.userid},#{file.file_name},FR1 not present"
      p "#{file.userid},#{file.file_name},FR1 not present"
      FR1 = false   
    end
      output_file.puts "****,#{file.userid},#{file.file_name},likely never processed" if FR1 && !FR2
      p "****,#{file.userid},#{file.file_name},likely never processed" if FR1 && !FR2

    
  end
  p "***************** Testing for unprocessed in base and #{args.fix}"
  output_file.puts  "******************Testing for unprocessed in base and #{args.fix}"
  record_number = 0
  PhysicalFile.not_waiting.not_processed.uploaded_into_base.no_timeout.order_by(userid: 1).each do |file|
    record_number = record_number + 1
    break if record_number == args.limit.to_i
    file_location = File.join(Rails.application.config.datafiles,file.userid,file.file_name)
    if File.file?(file_location)
      output_file.puts  "#{file.userid},#{file.file_name},FR2 file present"
      p "#{file.userid},#{file.file_name},FR2 file present"
    else 
      output_file.puts "#{file.userid},#{file.file_name},FR2 not present"
      p "#{file.userid},#{file.file_name},FR2 not present"
      file.remove_base_flag if args.fix.to_s == "fix"
    end
    file_location = File.join(Rails.application.config.datafiles_changeset,file.userid,file.file_name)
    if File.file?(file_location)
      output_file.puts  "#{file.userid},#{file.file_name},FR1 file present"
      p "#{file.userid},#{file.file_name},FR1 file present"
    else 
      output_file.puts "#{file.userid},#{file.file_name},FR1 not present"
      p "#{file.userid},#{file.file_name},FR1 not present"
      file.remove_change_flag if args.fix.to_s == "fix"
    end

  end
  p "************************ Testing for empty physical file and #{args.fix}"
  output_file.puts "***************** Testing for empty physical file and #{args.fix}"
  PhysicalFile.not_waiting.not_processed.not_uploaded_into_base.not_uploaded_into_change.no_timeout.order_by(userid: 1).each do |file|
      output_file.puts  "#{file.userid},#{file.file_name},nothing present"
      p "#{file.userid},#{file.file_name},nothing present"
      file.delete if args.fix.to_s == "fix"
  end
  output_file.puts Time.now 
  elapse = Time.now - start
  output_file.puts elapse
  output_file.close
  p "finished"
end
