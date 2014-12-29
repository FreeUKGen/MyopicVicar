class ReviewUseridFiles
  require 'userid_detail'
  require 'chapman_code'
  require 'get_files'
  require 'digest/md5'
  require 'syndicate'
  require 'syndicate_translation'

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
    'SyndicateName' => :syndicate_name,
    'SignUpDate' => :sign_up_date,
    'Person' => :person_role
  }



  def self.process(len,range)
    file_for_warning_messages = "log/review_userid_detail_file_message.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
    @@message_file = File.new(file_for_warning_messages, "w")
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    @@message_file.puts "This is a comparison of userids and the user fileset"
    userids = range.split("/")
    base_directory = Rails.application.config.datafiles
    filenames = Array.new
    p "starting"
    p range
    p userids
    if userids.length == 2
      pattern = File.join(base_directory,userids[0])
      p pattern
      files = Dir.glob(pattern, File::FNM_CASEFOLD).sort
     
      files.each do |filename|
        userid = filename.split("/")
        
        filenames << userid[4] unless userid[4].nil?
      end
    else
      @@message_file.puts "unknown range style"
    end
    p "There are #{filenames.length} user files"
    
    missing_userid = Array.new
    number = 0
    number_processed = 0
    number_missing = 0
    UseridDetail.each do |userid|

      number_processed = number_processed + 1
      
      if filenames.include?(userid.userid)
        number = number + 1
      else
        number_missing = number_missing + 1
        missing_userid << userid.userid
         p userid.userid
        @@message_file.puts "Dropped #{missing_userid} missing in the file }"
      end
    end
   p "We found #{number} and missed #{number_missing}"


  end #end process
end
