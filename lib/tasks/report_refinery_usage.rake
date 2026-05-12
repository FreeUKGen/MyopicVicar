task :report_refinery_usage => :environment do
  file_for_warning_messages = "log/Freereg2_usage_report.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
  @@message_file = File.new(file_for_warning_messages, "w")
  @@message_file.puts "User,Number,Last sign in"
  User.all.each do |user|
    unless user.sign_in_count.nil?
      @@message_file.puts "#{user.username},#{user.sign_in_count},#{user.last_sign_in_at}   "
    end
  end
end
