class ReportProblemEmailAddress
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


  def self.process(range)
    p "Creating, Updating and reporting errors in email addresses"
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    base_directory = Rails.application.config.datafiles
    filenames = Array.new
    files = Array.new
    userids = range.split("/")
    if userids.length == 2
      pattern = File.join(base_directory,userids[0])
      files = Dir.glob(pattern, File::FNM_CASEFOLD).sort
      files.each do |filename|
        pattern = File.join(filename,userids[1])
        fil = Dir.glob(pattern, File::FNM_DOTMATCH)
        filenames << fil[0] unless fil[0].nil?
      end
    else
      p "unknown range style"
    end
    file_for_warning_messages = "log/report_problem_email_address.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
    @@message_file = File.new(file_for_warning_messages, "w")
    number = 0
    p filenames.length
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



      userid = UseridDetail.where(:userid => header[:userid]).first
      if userid.nil?
        header[:person_role] = "transcriber" if header[:person_role].nil?
        header[:previous_syndicate] = header[:syndicate]
        header[:syndicate] = SyndicateTranslation.values_at(header[:syndicate]) if header[:syndicate_name].nil?
        #files written in F2 may have a non county syndicate name
        header[:syndicate] = header[:syndicate_name] unless header[:syndicate_name].nil?
        header[:digest] = Digest::MD5.file(filename).hexdigest
        header[:sign_up_date] = DateTime.strptime(header[:sign_up_date],'%s') unless header[:sign_up_date].nil?
        header[:disabled_date] = DateTime.strptime(header[:disabled_date],'%s') unless header[:disabled_date].nil?
        header[:fiche_reader] = header[:fiche_reader].to_i
        header[:fiche_reader] = false
        header[:active] = header[:active].to_i
        header[:disabled] = header[:disabled].to_i
        if header[:active] == 0 || header[:disabled] == 1 || !header[:disabled_date].nil? || !header[:disabled_reason].nil?
          header[:active] = false
        end

        p " #{header[:userid]} is not present and will be added"
        userid = UseridDetail.new(header)
        userid.save
        u = User.where(:username => header[:userid]).first
      else
        unless header[:email_address] == userid.email_address
          u = User.where(:username => header[:userid]).first
          u.email = nil
          u.save
          userid.update_attributes(:email_address => header[:email_address])
          u.email = header[:email_address]
          u.save
          p "#{header[:userid]} email address updating"

        end
      end


      if !userid.nil? && (userid.errors.any? )
        previous_userid = UseridDetail.where(:email_address => header[:email_address]).first
        previous_userid = previous_userid.userid unless previous_userid.nil?
        previous_user = User.where(:email => header[:email_address]).first
        previous_user = previous_user.username unless previous_user.nil?
        @@message_file.puts "#{header[:userid]};#{userid.errors.messages};#{header[:email_address]}; #{previous_userid}; #{previous_user}"
        p "#{header[:userid]};#{userid.errors.messages};#{header[:email_address]}; #{previous_userid}; #{previous_user}"
        p userid.errors.messages
      end #end errors


    end # end filename
    p "#{number} records processed"
  end #end process
end
