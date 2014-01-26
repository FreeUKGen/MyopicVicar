class CreateSyndicateDocs
require 'syndicate'
require 'chapman_code'
require 'get_files'
FIELD_NAMES = {
'Surname' => :person_surname,

 'UserID' => :userid,
  
   'DisabledDate' => :disabled_date,
    
      'Password' => :password,
       'EmailID' => :email_address,
        'Disabled' => :disabled,
         'Active' => :active,
         
          'GivenName' => :person_forename,
         
             'FicheReader' => :fiche_reader,
              'DisabledReason' => :disabled_reason,
               'Country' => :address,
                'SubmitterNumber' => :submitter_number,
                 'SyndicateID' => :syndicate,

                 
                   'SignUpDate' => :sign_up_date
                   

}
def self.slurp_the_csv_file(filename)
               
    begin
          #we slurp in the full csv file
          @@array_of_data_lines = CSV.read(filename)
          p filename
          p @@array_of_data_lines
          success = true
          #we rescue when for some reason the slurp barfs
               
    end #begin end
   return success
  end #method end


 def self.process(type,base_directory,range)
      @@array_of_data_lines = Array.new {Array.new}
      header = Hash.new
 	   file_for_warning_messages = "log/syndicate_messages.log"
     FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
     @@message_file = File.new(file_for_warning_messages, "a")
     p "Started a syndicate build with options of #{type} with a base directory at #{base_directory} and a file #{range}"
     @@message_file.puts  "Started a syndicate build with options of #{type} with a base directory at #{base_directory} and a file #{range}"
     filename = base_directory + range
     p filename
     success = slurp_the_csv_file(filename)
     p "csv slurp failed" unless success == true
     @@message_file.puts "csv slurp failed" unless success == true
      @@number_of_line = 0
      loop do
        break if @@array_of_data_lines[@@number_of_line].nil?
        data = @@array_of_data_lines[@@number_of_line] 
        p data
        header[:chapman_code] = data[0]
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
          p "Syndicate #{record.syndicate_code} successfully saved"
          @@message_file.puts "Syndicate #{record.syndicate_code} successfully saved"
        end #if
        @@number_of_line = @@number_of_line + 1
      end #loop
 
 end #end process
end
