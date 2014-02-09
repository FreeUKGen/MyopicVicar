class CreateSyndicateDocs
require 'syndicate'
require 'chapman_code'
require 'get_files'

def self.slurp_the_csv_file(filename)
               
    begin
          #we slurp in the full csv file
          @@array_of_data_lines = CSV.read(filename)
         
          success = true
          #we rescue when for some reason the slurp barfs
               
    end #begin end
   return success
  end #method end


 def self.process(type,range)
      Syndicate.delete_all if type = "recreate"
      @@array_of_data_lines = Array.new {Array.new}
      base_directory = Rails.application.config.datafiles
      header = Hash.new
 	   file_for_warning_messages = "log/syndicate_messages.log"
     FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
     @@message_file = File.new(file_for_warning_messages, "w")
     p "Started a syndicate build with options of #{type} with a base directory at #{base_directory} and a file #{range}"
     @@message_file.puts  "Started a syndicate build with options of #{type} with a base directory at #{base_directory} and a file #{range}"
     filename = base_directory + range
     success = slurp_the_csv_file(filename)
     p "csv slurp failed" unless success == true
     @@message_file.puts "csv slurp failed" unless success == true
      @@number_of_line = 0
      loop do
        break if @@array_of_data_lines[@@number_of_line].nil?
        data = @@array_of_data_lines[@@number_of_line] 
       
        header[:syndicate_code] = data[0]
        header[:syndicate_coordinator] = data[1]
        record = Syndicate.new(header)
        record.save
        if record.errors.any?
           p  "Syndicate #{record.syndicate_code} creation failed for following reasons"
          p record.errors
          @@message_file.puts "Syndicate #{record.syndicate_code} creation failed for following reasons"
           p record.errors
         
        else
         
          @@message_file.puts "Syndicate #{record.syndicate_code} successfully saved"
        end #if
        @@number_of_line = @@number_of_line + 1
      end #loop
 
 end #end process
end
