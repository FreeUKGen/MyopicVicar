task :extract_userids_passwords_for_image_server,[:limit] => [:environment] do |t, args|
  file_for_warning_messages = "#{Rails.root}/log/REG_users"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  output_file = File.new(file_for_warning_messages, "w")
  start = Time.now
  puts start
  record_number = 0
  UseridDetail.no_timeout.each do |user|
    p user.userid.present?
    p user.password.present?
    p user.registration_completed(user)
    p user.active == 'true'
    if user.userid.present? && user.password.present? && user.registration_completed(user) && user.active == 'true'
      record_number =  record_number + 1
      output_file.puts "#{user.userid}:[FreeREG]#{user.password}" 
    end
  end
  elapse = Time.now - start
  puts "Output #{record_number} userids to #{ file_for_warning_messages} at #{Time.now} in #{elapse} seconds"
  output_file.close
  p "finished"
end
