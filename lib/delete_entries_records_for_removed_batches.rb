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
    p " There are #{UseridDetail.count} userids"
    number = 0
    Freereg1CsvFile.each do |all_file|
      number = number + 1
      userid = all_file.userid
      all_files[userid] = Array.new unless all_files.has_key?(userid)
      all_files[userid] << all_file.file_name
    end
    p "There are #{number} loaded files"
    total_base_pattern = File.join(base_directory,"*","*.csv")
    total_change_pattern = File.join(base_directory,"*","*.csv")
    total_base_files = Dir.glob(total_base_pattern, File::FNM_CASEFOLD).sort
    total_change_files = Dir.glob(total_change_pattern, File::FNM_CASEFOLD).sort
    p "#{total_base_files} base files and #{total_change_files}" 
    
    total_base_files_hash = Hash.new
    total_base_files.each do |total_base_file|
      file_parts = total_base_file.split("/")
      file_name = file_parts[-1]
      user_id = file_parts[-2]
      total_base_files_hash[user_id] = Array.new unless total_base_files_hash.has_key?(user_id)
      total_base_files_hash[user_id] << file_name
    end

    total_change_files_hash = Hash.new
    total_change_files.each do |total_change_file|
      file_parts = total_change_file.split("/")
      file_name = file_parts[-1]
      user_id = file_parts[-2]
      total_change_files_hash[user_id] = Array.new unless total_change_files_hash.has_key?(user_id)
      total_change_files_hash[user_id] << file_name
    end
    total_change_files_hash_copy = total_change_files_hash
    total_base_files_hash_copy = total_base_files_hash

    all_files.each_pair do |user,file_array|
      file_array.each do |file_name|
       total_change_files_hash[user].delete_if {|name| name = file_name} unless    total_change_files_hash[user].nil?
       total_base_files_hash[user].delete_if {|name| name = file_name} unless      total_base_files_hash[user].nil?
       end
    end 
    @@message_file.puts "The following userids have files in the change directory but not in the database"

    total_change_files_hash.each_pair do |user,file_array|
        unless file_array.empty?
          @@message_file.puts user
          @@message_file.puts file_array
        end 
      end
     @@message_file.puts "The following userids have files in the base directory but not in the database"
     total_base_files_hash.each_pair do |user,file_array|
        unless file_array.empty?
          @@message_file.puts user
          @@message_file.puts file_array
        end 
      end
     total_change_files_hash_copy.each_pair do |user,file_array|
      file_array.each do |file_name|
      total_base_files_hash_copy[user].delete_if {|name| name = file_name} unless    total_base_files_hash_copy[user].nil?
    end
  end
    @@message_file.puts "The following userids have files in the base directory but they are not present in the change directory"
     total_base_files_hash_copy.each_pair do |user,file_array|
        unless file_array.empty?
          @@message_file.puts user
          @@message_file.puts file_array
        end 
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
       
        number_of_files = 0
        number_of_files = process_files.length unless process_files.nil?
        base_pattern = File.join(base_directory,userid,"*.csv")
        base_files = Dir.glob(base_pattern, File::FNM_CASEFOLD).sort
        change_pattern = File.join(change_directory,userid,"*.csv")
        files = Dir.glob(change_pattern, File::FNM_CASEFOLD).sort

       
         files.each do |file|
         file_parts = file.split("/")
         file_name = file_parts[-1]
         all_files[userid].delete_if {|name| name = file_name} unless all_files[userid].nil?
         process_files.delete_if {|name| name = file_name}
        end
        
        number_deleted = 0
        unless process_files.empty?
          @@message_file.puts "remove files for #{userid}" 
          process_files.each do |my_file|
          number_deleted = number_deleted + 1
          delete_file = File.join(base_directory,userid,my_file)
          @@message_file.puts delete_file
          #File.delete(delete_file) if File.exists?(delete_file)
          Freereg1CsvFile.where(userid: userid,file_name: my_file).all.each do |del_file|
            #del_file.destroy
           @@message_file.puts del_file
          end
        end
         @@message_file.puts "#{userid}, #{number_of_files},#{number_deleted},  #{files.length}, #{base_files.length}"
        else
         @@message_file.puts "#{userid}, #{number_of_files},0,  #{files.length}, #{base_files.length}"
        end
        
      end
    end
  @@message_file.puts "The following userids have processed files but they are not present in the change directory"

all_files.each_pair do |user,file_array|
unless file_array.empty?
@@message_file.puts user
@@message_file.puts file_array
end
end
    
  end #end process
end
