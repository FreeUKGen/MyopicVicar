class CreateCountyDocs
require 'county'
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
  @except = ["ENG","IRL","SCT","WLS","SYNManager","REGManager","GENManager","nil"]
      County.delete_all if type = "recreate"
      @@array_of_data_lines = Array.new {Array.new}
      base_directory = Rails.application.config.datafiles
      header = Hash.new
 	   file_for_warning_messages = "log/county_messages.log"
     FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
     @@message_file = File.new(file_for_warning_messages, "w")
     p "Started a county build with options of #{type} with a base directory at #{base_directory} and a file #{range}"
     @@message_file.puts  "Started a county build with options of #{type} with a base directory at #{base_directory} and a file #{range}"
     filename = File.join(base_directory, range)
     success = slurp_the_csv_file(filename)
     p "csv slurp failed" unless success == true
     @@message_file.puts "csv slurp failed" unless success == true
      number_of_county_coordinators = 0
      @@number_of_line = 0
      loop do
        break if @@array_of_data_lines[@@number_of_line].nil?
        data = @@array_of_data_lines[@@number_of_line] 
        unless @except.include?(data[0])
        number_of_county_coordinators =  number_of_county_coordinators + 1
        header[:chapman_code] = data[0] 
        header[:county_coordinator] = data[1] 
        record = County.new(header)
        record.save
        if record.errors.any?
           p  "County #{data[0]} creation failed for following reasons"
          p record.errors
          @@message_file.puts "County #{data[0]} creation failed for following reasons"
           p record.errors
         
        else
      
          @@message_file.puts "County #{data[0]} successfully saved"
        end #if
        end
        @@number_of_line = @@number_of_line + 1
       
      end #loop
 p "#{@@number_of_line} lines processed with #{number_of_county_coordinators} county coordinators"
 end #end process
end
