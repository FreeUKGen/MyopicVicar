class DeleteEntriesRecordsForRemovedBatches
  def self.process(len,fr)
    file_for_warning_messages = "log/delete_entries_records_for_removed_batches.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
    @@message_file = File.new(file_for_warning_messages, "w")
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
   
    #extract range of userids
    base_directory = Rails.application.config.datafiles if fr.to_i == 2
    base_directory = Rails.application.config.datafiles_changeset if fr.to_i == 1
     puts "Deleting entries and records for removed batches from the files collection at #{base_directory}"
    len =len.to_i
    
    count = 0
    userids= UseridDetail.all.order_by(userid: 1)
    userids.each do |user|
      userid = user.userid
      unless userid.nil?
        count = count + 1
        break if count == len
        process_files = Array.new
        Freereg1CsvFile.where(userid: userid).order_by(file_name: 1).each do |name| 
          process_files << name.file_name
        end
      
        pattern = File.join(base_directory,userid,"*.csv")
        files = Dir.glob(pattern, File::FNM_CASEFOLD).sort
     
        files.each do |file|
         file_parts = file.split("/")
         file_name = file_parts[-1]
       
         process_files.delete_if {|name| name = file_name}
        end
        unless process_files.empty?
        p "remove files for #{userid}" 
        p process_files  
         process_files.each do |my_file|
          Freereg1CsvFile.where(userid: userid,file_name: my_file).all.each do |del_file|
            del_file.destroy
          end
         end
        end
      end
    end
    
  end #end process
end
