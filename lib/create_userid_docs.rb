class CreateUseridDocs
require 'userid_detail'
require 'chapman_code'
require 'get_files'
require 'digest/md5'
require 'syndicate'

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

                 
                   'SignUpDate' => :sign_up_date,
                  'Person' => :person_role
                   

}

def self.check_for_replace(filename,header)
                 
    #check to see if we should process the file
    #is it aleady there?
    check_for_file = UseridDetail.where({ :userid => header[:userid]}).first
    if check_for_file.nil?
    #if file not there then need to create
      return true
    else
      #file is in the database
      
      if header[:digest] == check_for_file.digest then
        #file in database is same or more recent than we we are attempting to reload so do not process
              @@message_file.puts "#{userid} #{header[:file_name]} has not changed since last build"
              return false
      else
        UseridDetail.delete_file(check_for_file._id)
         return true
      end
         
    end #check_for_file loop end

  end #method end

 def self.process(type,range)
 	
  base_directory = Rails.application.config.datafiles
  UseridDetail.delete_all if type = "recreate"
 	filenames = GetFiles.get_all_of_the_filenames(base_directory,range)

     file_for_warning_messages = "log/userid_detail_messages.log"
     FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
     @@message_file = File.new(file_for_warning_messages, "w")
     
     @@message_file.puts  "Started a Userid Detail build with options of #{type} with a base directory at #{base_directory} and a file #{range}"


  number = 0
   number_of_syndicate_coordinators = 0
   number_of_county_coordinators = 0
 number_of_country_coordinators = 0

  filenames.each do |filename|
   number = number + 1
   
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
  
   header[:person_role] = "transcriber" if header[:person_role].nil?
   header[:chapman_code] = header[:syndicate]
   header[:digest] = Digest::MD5.file(filename).hexdigest 
    
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
    
    syndicates_count = Syndicate.where(:syndicate_coordinator => header[:userid]).count
    

    unless syndicates_count == 0
      number_of_syndicate_coordinators =  number_of_syndicate_coordinators  + 1
      syndicates = Syndicate.where(:syndicate_coordinator => header[:userid]).all
      header[:person_role] = "syndicate_coordinator"
       header[:syndicate_groups] = Array.new
      syndicates.each do |syndicate|
        header[:syndicate_groups] <<  syndicate.syndicate_code
      end
      
    else

    end

   counties_count = County.where(:county_coordinator => header[:userid]).count

   
    
    unless counties_count == 0
       number_of_county_coordinators =  number_of_county_coordinators + 1
      counties = County.where(:county_coordinator => header[:userid]).all

      header[:person_role] = "county_coordinator"
       header[:county_groups] = Array.new
      counties.each do |county|
        header[:county_groups] <<  county.chapman_code
      end
       
    else
     
    end
    countries_count = Country.where(:country_coordinator => header[:userid]).count
   
    unless countries_count == 0
       number_of_country_coordinators =  number_of_country_coordinators + 1
      countries = Country.where(:country_coordinator => header[:userid]).all
      header[:person_role] = "country_coordinator"
       header[:country_groups] = Array.new
      countries.each do |country|
        header[:country_groups] <<  country.chapman_code
      end 
      
    else 
      
    end

   header[:person_role] = "system_administrator" if header[:userid] == "REGManager" 
   process = true   
   process = check_for_replace(filename,header) unless type == "recreate"   
   
   detail = UseridDetail.new(header)
   detail.save if process == true
    if detail.errors.any?
     @@message_file.puts detail.errors
    end #end errors
    
  end # end filename
  @@message_file.puts"#{number} records added with #{number_of_syndicate_coordinators} syndicate coordinators, #{number_of_county_coordinators} county coordinators #{number_of_country_coordinators} country coordinators"
 end #end process
end