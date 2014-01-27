class CreateUseridDocs
require 'userid_detail'
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



 def self.process(type,base_directory,range)
 	fields = Hash.new
  header = Hash.new
 	filenames = GetFiles.get_all_of_the_filenames(base_directory,range)

  filenames.each do |filename|
   
      fields = Hash.new
  header = Hash.new
  records = Array.new
    record = File.open(filename).read
	  records = record.split("\n")
  
    records.each do |r|
    	rx = r.split(":")
    	fields[rx[0]] = rx[1]
    end #end record split

    
    fields.each_key do |fn|
    	recs = FIELD_NAMES.assoc(fn)
      unless recs.nil?
        x  = fields.assoc(fn)
        header[recs[1]] = x[1]
      end # end unless
    end #end field
   
   header[:person_role] = "transcriber"
   header[:chapman_code] = header[:syndicate]
   
 
  header[:sign_up_date] = DateTime.strptime(header[:sign_up_date],'%s') unless header[:sign_up_date].nil?
   header[:disabled_date] = DateTime.strptime(header[:disabled_date],'%s') unless header[:disabled_date].nil?
   header[:fiche_reader] = header[:fiche_reader].to_i

     if  header[:fiche_reader] == 1
       header[:fiche_reader] = true
     else
      header[:fiche_reader] = false
     end
   
 header[:active] = header[:active].to_i

      if  header[:active] == 1
       header[:active] = true
     else
      header[:active] = false
     end
      
header[:disabled] = header[:disabled].to_i

     if  header[:disabled] == 1
       header[:active] = false
     
     else
       header[:active] = true
      
     end
   detail = UseridDetail.new(header)
   detail.save
    if detail.errors.any?
     p detail.errors
    end #end errors
  end # end filename
 end #end process
end