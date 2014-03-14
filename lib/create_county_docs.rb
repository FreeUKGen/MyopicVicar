class UpdateFreeregSyndicate
 require 'userid_detail'
 require 'Freereg1-csv_file'

def self.process(type,range)
 
     
 	   file_for_warning_messages = "log/update_freereg_syndicate_messages.log"
     FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
     message_file = File.new(file_for_warning_messages, "w")
     p "Started a county build with options of #{type} with a base directory at #{base_directory} and a file #{range}"
     message_file.puts  "Started a county build with options of #{type} with a base directory at #{base_directory} and a file #{range}"
    users = UseridDetail.all 
    n_u = 0
    n_f = 0
    users.each do |user|
      n_u = n_u + 1
      files = Freereg1CsvFile.where(:userid = user.userid).all
      files.each do |file|
        n_f = n_f + 1
        file.transcriber_syndicate = user.syndicate
        #file.save!
      end
    end
 p "#{n_f} files processed for #{n_u} userids"
 end #end process
end
