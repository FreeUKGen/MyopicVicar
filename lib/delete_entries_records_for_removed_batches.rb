class DeleteEntriesRecordsForRemovedBatches
  def self.process

    file_for_warning_messages = File.join(Rails.root,"log/delete_entries_records_for_removed_batches")
    time = Time.new.to_i.to_s
    file_for_warning_messages = (file_for_warning_messages + "." + time + ".log").to_s
    @@message_file = File.new(file_for_warning_messages, "w")
    
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    @@message_file.puts " Using #{Rails.application.config.website}"

   
    #extract range of userids
    base_directory = Rails.application.config.datafiles 
   
    report_time = Time.now.strftime("%d/%m/%Y %H:%M")
    puts "Deleting entries and records for removed batches from the base files collection at #{base_directory} that was run at #{report_time}"
    @@message_file.puts "Deleting entries and records for removed batches from the base files collection at #{base_directory} that was run at #{report_time}"
    len =len.to_i
    
    userids = Array.new
    users = UseridDetail.all.order_by(userid: 1)
    users.each do |user|
      userids << user.userid
    end

    total_userid_pattern = File.join(base_directory,"*",".udetails")
    total_userid_files = Dir.glob(total_userid_pattern, File::FNM_CASEFOLD).sort
    
    p "There are #{userids.length} userids and #{total_userid_files.length} userid files" 
    @@message_file.puts "There are #{userids.length} userids and #{total_userid_files.length} userid files" 
     @@message_file.puts "Checking they all exist"
    total_userid_files.each do |file|
      file_parts = file.split("/")
      userid = file_parts[-2]
      unless UseridDetail.where(userid: userid).exists?
        p "#{userid} not in the database"
        @@message_file.puts "#{userid} not in the database"
      end
    end
    
     @@message_file.close
    file = @@message_file
    user = UseridDetail.where(userid: "REGManager").first
    UserMailer.update_report_to_freereg_manager(file,user).deliver
    user = UseridDetail.where(userid: "Captainkirk").first
    UserMailer.update_report_to_freereg_manager(file,user).deliver
  end #end process
end
