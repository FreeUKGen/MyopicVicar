class DeleteEntriesRecordsForRemovedBatches
  def self.process(len,fr)
    file_for_warning_messages = "log/delete_entries_records_for_removed_batches"
    time = Time.new.to_i.to_s
    file_for_warning_messages = (file_for_warning_messages + "." + time + ".log").to_s
    @@message_file = File.new(file_for_warning_messages, "w")
    
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
   
    #extract range of userids
    base_directory = Rails.application.config.datafiles 
    change_directory = base_directory
    change_directory = Rails.application.config.datafiles_changeset if fr.to_i == 1
    puts "Deleting entries and records for removed batches from the base files collection at #{base_directory} using the change set at #{change_directory}"
    @@message_file.puts "Deleting entries and records for removed batches from the base files collection at #{base_directory} using the change set at #{change_directory}"
    len =len.to_i
    
    count = 0
    all_files = Hash.new
    userids = UseridDetail.all.order_by(userid: 1)
    Freereg1CsvFile.each do |all_file|
      userid = all_file.userid
      all_files[userid] = Array.new unless all_files.has_key?(userid)
      all_files[userid] << all_file.file_name
    end

    userids.each do |user|
      userid = user.userid

      unless userid.nil?
        count = count + 1
        break if count == len
        process_files = Array.new
        Freereg1CsvFile.where(userid: userid).order_by(file_name: 1).each do |name| 
          process_files << name.file_name
        end
       p userid
        p process_files
        p all_files[userid] 
        number_of_files = 0
        number_of_files = process_files.length unless process_files.nil?
       
        pattern = File.join(change_directory,userid,"*.csv")
        files = Dir.glob(pattern, File::FNM_CASEFOLD).sort
       
        files.each do |file|
         file_parts = file.split("/")
         file_name = file_parts[-1]
         all_files[userid].delete_if {|name| name = file_name} unless all_files[userid].nil?
         process_files.delete_if {|name| name = file_name}
        end
        p userid
        p process_files
        p all_files[userid]
        number_deleted = 0
        unless process_files.empty?
          p "remove files for #{userid}" 
          process_files.each do |my_file|
          number_deleted = number_deleted + 1
          delete_file = File.join(base_directory,userid,my_file)
          p delete_file
          #File.delete(delete_file) if File.exists?(delete_file)
          Freereg1CsvFile.where(userid: userid,file_name: my_file).all.each do |del_file|
            #del_file.destroy
            p del_file
          end
        end
         @@message_file.puts "#{userid}, #{number_of_files},#{number_deleted}"
        else
         @@message_file.puts "#{userid}, #{number_of_files},0"
        end
        
      end
    end
    p "The following userids have processed files but they are not present in the change directory"
    p all_files
    all_files.each_pair do |user,file_array|
        unless file_array.empty?
          p user
          p file_array

        end 
      end
    
  end #end process
end
