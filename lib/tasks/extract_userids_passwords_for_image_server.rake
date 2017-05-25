task :extract_userids_passwords_for_image_server,[:limit] => [:environment] do |t, args|
  file_for_warning_messages = "#{Rails.root}/log/REG_users"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  output_file = File.new(file_for_warning_messages, "w")
  start = Time.now
  puts start
  record_number = 0
  records = UseridDetail.count
  UseridDetail.no_timeout.each do |user|
    output_file.puts "#{user.userid}:[FreeREG]#{user.password}" if user.userid.present? && user.password.present? && user.registration_completed(user) && user.active == 'true'
  end
  elapse = Time.now - start
  puts "Output #{records} userids to #{ file_for_warning_messages} at #{Time.now} in #{elapse} seconds"
  output_file.close
  p "finished"
end
