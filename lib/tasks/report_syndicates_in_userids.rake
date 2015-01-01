task :report_syndicates_in_userids => :environment do
  #This task resets the coordinators and their roles based on the syndicate coordinators collection
  puts "Dumping Syndicate names in userids."
  file_for_warning_messages = "log/syndicates_in_userids.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
  @@message_file = File.new(file_for_warning_messages, "w")
  Mongoid.load!("#{Rails.root}/config/mongoid.yml")


  UseridDetail.each do |user|
    user.previous_syndicate = "" if user.syndicate.nil?
    user.syndicate = 'Unknown'  if user.syndicate.nil?
  end
  
  UseridDetail.each do |user|
    @@message_file.puts "#{user.userid},#{user.syndicate},#{user.previous_syndicate}"
  end

  p 'finished'
end
