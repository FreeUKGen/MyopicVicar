class LoadFilesIntoUseridDetails
  require 'chapman_code'
  require 'userid_detail'
  require 'freereg1_csv_file'
  require 'attic_file'
  require 'get_files'
  require 'digest/md5'
 
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
    file_for_warning_messages = "log/load_files_into_userid_details.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
    @@message_file = File.new(file_for_warning_messages, "w")
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    puts "Loading files into useris_details and into attic files collection"
    #extract range of userids
    userids = range.split("/")
    base_directory = Rails.application.config.datafiles if fr.to_i == 2
    base_directory = '/raid/freereg2/freereg1/users' if fr.to_i == 1
    if Rails.application.config.mongodb_bin_location == 'd:/mongodb/bin/'
      offset = 2
    else
     offset = 4 if fr.to_i == 2
      offset = 5 if fr.to_i == 1 
    end
    filenames = Hash.new
    attic_filenames = Hash.new
    if userids.length == 2
      pattern = File.join(base_directory,userids[0])
      files = Dir.glob(pattern, File::FNM_CASEFOLD).sort
      files.each do |filename|
        userid = filename.split("/")
        dir = File.join(base_directory,userid[offset],userids[1])
        files_for = Dir.glob(dir, File::FNM_CASEFOLD).sort
        filenames[userid[offset]] = files_for unless userid[offset].nil?
        attic_dir = File.join(base_directory,userid[offset],".attic","#{userids[1]}.*")
        attic_files_for = Dir.glob(attic_dir, File::FNM_CASEFOLD | File::FNM_DOTMATCH).sort
        attic_filenames[userid[offset]] = attic_files_for unless userid[offset].nil?
      end
    else
      @@message_file.puts "unknown range style"
    end
    p "There are #{filenames.length} userid files"
    number_missed = 0
    number_files_missed = 0
    missing_files = Hash.new
    filenames.each_pair do |name,value|
      unless UseridDetail.where(:userid => name).exists?
        number_missed = number_missed + 1
        @@message_file.puts "#{name} missing from userids "
     else
       missing_files[name] = Array.new
       value.each do |file|
         file_parts = file.split("/")
         unless Freereg1CsvFile.where(:userid => name,:file_name => file_parts[-1]).exists?
           number_files_missed = number_files_missed + 1
            missing_files[name] << file
         else
            my_user = UseridDetail.where(:userid => name).first
            my_files = Freereg1CsvFile.where(:userid => name,:file_name => file_parts[-1]).all
            my_files.each do |my_file|
              my_file.userid_detail = my_user
              my_file.save
            end
            # 
         end 
       end
     end
  end
 attic_filenames.each_pair do |name,value|
      if  UseridDetail.where(:userid => name).exists?
        my_user = UseridDetail.where(:userid => name).first
        value.each do |file|
          file_parts = file.split("/")
          date = file_parts[-1].split(".")
          date[2] = date[2].gsub(/\D/,"")
          date_file = DateTime.strptime(date[2],'%s') unless date[2].nil?
          attic = AtticFile.new(:name => file_parts[-1],:date_created => date_file)
          attic.userid_detail = my_user
          attic.save 
        end
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

    p "Out of #{filenames.length} user files we found #{number} loaded and #{number_missed} missing userids and had #{number_missing} userids without user files "
    @@message_file.puts missing_userid
 
    @@message_file.puts missing_files
    


  end #end process
end
