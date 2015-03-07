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



  def self.process(len,range,fr)
    file_for_warning_messages = "log/review_userid_detail_file_message.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
    @@message_file = File.new(file_for_warning_messages, "w")
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    @@message_file.puts "This is a comparison of userids and the user fileset"
    userids = range.split("/")
    base_directory = Rails.application.config.datafiles if fr == 2
    base_directory = '/raid/freereg2/freereg1/users' if fr == 1
    filenames = Array.new
    p "starting comparison of userid with #{base_directory}"
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
    number_missed = 0
    filenames.each do |name|
      unless UseridDetail.where(:userid => name).exists?
        number_missed = number_missed + 1
        @@message_file.puts "#{name} missing from userids "
      end
    end

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
        @@message_file.puts "Dropped #{userid.userid} missing in the files }"
        @@message_file.puts "#{userid.inspect}"
      end
    end

    p "Out of #{filenames.length} we found #{number} and #{number_missed} userids and had #{number_missing} userids without files "
    @@message_file.puts missing_userid


  end #end process
end
