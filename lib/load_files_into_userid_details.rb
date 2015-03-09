class LoadFilesIntoUseridDetails
  require 'chapman_code'
  require 'userid_detail'
  require 'freereg1_csv_file'
  require 'attic_file'
  require 'get_files'
  require 'digest/md5'
 
  def self.process(len,type,fr)
    file_for_warning_messages = "log/load_files_into_userid_details.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
    @@message_file = File.new(file_for_warning_messages, "w")
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    puts "Loading files into useris_details and into attic files collection"
    #extract range of userids
    base_directory = Rails.application.config.datafiles if fr.to_i == 2
    base_directory = Rails.application.config.datafiles_changeset if fr.to_i == 1
    
    len =len.to_i
    if type == "files" || type == "both"
      count = 0
      UseridDetail.each do |user|
        count = count + 1
        break if count == len
         userid = user.userid
         pattern = File.join(base_directory,userid,"*.csv")
         p pattern
         files = Dir.glob(pattern, File::FNM_CASEFOLD).sort
         p files
         if files.nil?
          @@message_file.puts "#{userid}, has,0, files "
         else
          @@message_file.puts "#{userid}, has ,#{files.length}, files "
          files.each do |file|
             file_parts = file.split("/")
             file_name = file_parts[-1]
             if Freereg1CsvFile.where(:userid => userid,:file_name => file_name).exists?
              my_file = Freereg1CsvFile.where(:userid => name,:file_name => file_name).first
              my_file.userid_detail = user 
              my_file.save
               @@message_file.puts "#{userid}, has file,#{file_name}, added " 
             else
              @@message_file.puts "#{userid}, has file,#{file_name}, not processed "
             end 
           end
         end
      end
    end
    if type == "attic" || type == "both"
      count = 0
      UseridDetail.each do |user|
        count = count + 1
        break if count == len
         userid = user.userid
         pattern = File.join(base_directory,userid,".attic/*.csv.*")
         p pattern
         files = Dir.glob(pattern, File::FNM_CASEFOLD).sort
         p files
         if files.nil?
          @@message_file.puts "#{userid}, has ,0, attic files "
         else
          @@message_file.puts "#{userid}, has ,#{files.length}, attic files "
          files.each do |file|
            file_parts = file.split("/")
            date = file_parts[-1].split(".")
            date[2] = date[2].gsub(/\D/,"")
            date_file = DateTime.strptime(date[2],'%s') unless date[2].nil?
            attic_file =  AtticFile.new(:name => file_parts[-1],:date_created => date_file,:userid => userid)
            attic_file.userid_detail = user
            attic_file.save
            @@message_file.puts "#{userid}, has attic file ,#{file_parts[-1]}, added " 
           end
         end
      end
    end 
    if type == "attic" || type == "both"
      count = 0
      UseridDetail.each do |user|
        count = count + 1
        break if count == len
         userid = user.userid
         pattern = File.join(base_directory,userid,".attic/.uDetails.*")
         p pattern
         files = Dir.glob(pattern, File::FNM_CASEFOLD).sort
         p files
         if files.nil?
          @@message_file.puts "#{userid}, has ,0, attic uDetails "
         else
          @@message_file.puts "#{userid}, has ,#{files.length}, attic uDetails "
          files.each do |file|
            file_parts = file.split("/")
            date = file_parts[-1].split(".")
            date[2] = date[2].gsub(/\D/,"")
            date_file = DateTime.strptime(date[2],'%s') unless date[2].nil?
            attic_file =  AtticFile.new(:name => file_parts[-1],:date_created => date_file,:userid => userid)
            attic_file.userid_detail = user
            attic_file.save
            @@message_file.puts "#{userid}, has attic uDetails ,#{file_parts[-1]}, added " 
           end
         end
      end
    end     
  end #end process
end
