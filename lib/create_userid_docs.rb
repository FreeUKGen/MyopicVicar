class CreateUseridDocs
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

  def self.check_for_replace(filename,userid,digest)
    #check to see if we should process the file
    #is it already there?
    check_for_file = UseridDetail.where(:userid => userid).first
    if check_for_file.nil?
      #if file not there then need to create
      return true
    else
      #file is in the database

      if digest == check_for_file.digest then
        #file in database is same or more recent than we we are attempting to reload so do not process
        @@message_file.puts "#{userid} #{filename} has not changed since last build"
        return false
      else
        return true
      end

    end #check_for_file loop end

  end #method end

  def self.process(type,range)
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
    file_for_warning_messages = "log/userid_detail_messages.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
    @@message_file = File.new(file_for_warning_messages, "w")
    @@message_file.puts  "Started a Userid Detail build with options of #{type} with a base directory at #{base_directory} and a range #{range} that translates to #{filenames.length} userids"
    p "Started a Userid Detail build with options of #{type} with a base directory at #{base_directory} and a range #{range} that translates to #{filenames.length} userids"

    if type == 'recreate'
      User.all.each do |user|
        user.destroy unless user.username == 'Captainkirk'
      end
    end

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
        r = r.chomp
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



      if header[:active] == 0  || header[:disabled] == 1 || !header[:disabled_date].nil? || !header[:disabled_reason].nil?
        header[:active] = false
      end




      syndicates_count = Syndicate.where(:syndicate_coordinator => header[:userid]).count

      header[:syndicate_groups] = Array.new
      unless syndicates_count == 0
        number_of_syndicate_coordinators =  number_of_syndicate_coordinators  + 1
        syndicates = Syndicate.where(:syndicate_coordinator => header[:userid]).all
        header[:person_role] = "syndicate_coordinator"

        syndicates.each do |syndicate|
          header[:syndicate_groups] <<  syndicate.syndicate_code
        end

      else

      end

      counties_count = County.where(:county_coordinator => header[:userid]).count


      header[:county_groups] = Array.new
      unless counties_count == 0
        number_of_county_coordinators =  number_of_county_coordinators + 1
        counties = County.where(:county_coordinator => header[:userid]).all

        header[:person_role] = "county_coordinator"

        counties.each do |county|
          header[:county_groups] <<  county.chapman_code
        end

      else

      end
      header[:country_groups] = Array.new
      countries_count = Country.where(:country_coordinator => header[:userid]).count

      unless countries_count == 0
        number_of_country_coordinators =  number_of_country_coordinators + 1
        countries = Country.where(:country_coordinator => header[:userid]).first

        header[:person_role] = "country_coordinator"


        header[:country_groups] =  countries.counties_included


      else

      end

      header[:person_role] = "system_administrator" if header[:userid] == "REGManager"
      header[:person_role] = "system_administrator" if header[:userid] == "Captainkirk"
      header[:person_role] = "system_administrator" if header[:userid] == "smrr723"
      header[:person_role] = "data_manager" if header[:userid] == "ericb"
      header[:person_role] = "data_manager" if header[:userid] == "kirkbedfordshire"

      if check_for_replace(filename,header[:userid],header[:digest]) ||  type == "recreate"
        if type == "recreate"
          old_detail = UseridDetail.where(:userid => header[:userid]).first
          unless old_detail.nil?
            header[:last_upload] = old_detail.last_upload
            header[:number_of_files] = old_detail.number_of_files
            header[:number_of_records] = old_detail.number_of_records
            header[:skill_level] = old_detail.skill_level
            header[:previous_syndicate] = old_detail.previous_syndicate
            header[:person_role] = old_detail.person_role
            header[:syndicate_groups] = old_detail.syndicate_groups
            header[:county_groups] = old_detail.county_groups
            header[:country_groups] = old_detail.country_groups
            header[:skill_notes] = old_detail.skill_notes
            header[:transcription_agreement] = old_detail.transcription_agreement
            header[:new_transcription_agreement] = old_detail.new_transcription_agreement
            header[:technical_agreement] = old_detail.technical_agreement
            header[:research_agreement] = old_detail.research_agreement
            old_detail.delete
          end
          refinery_user = User.where(:username => userid.userid).first
          refinery_user.destroy unless refinery_user.nil?
        end

        userid = UseridDetail.where(:userid => header[:userid]).first
        unless userid.nil?
          header.delete(:email_address)  if header[:email_address] == userid.email_address
          userid.update_attributes(header)
          p "#{header[:userid]} updated"
        else
          header.delete(:syndicate_name)
          header.delete(:disabled)
          userid = UseridDetail.new(header)
          if type == 'recreate'

            userid.save(:validate => false)
          else

            userid.save
          end
        end


        if userid.errors.any?
          @@message_file.puts "#{header[:userid]} not created"
          @@message_file.puts userid.errors.messages
          p "#{header[:userid]} not created"
          p userid.errors.messages
        else
        @@message_file.puts  "#{header[:userid]} created"
        p "#{header[:userid]} created"
        end #end errors
      end

    end # end filename
    p "#{number} records added with #{number_of_syndicate_coordinators} syndicate coordinators, #{number_of_county_coordinators} county coordinators #{number_of_country_coordinators} country coordinators"
    @@message_file.puts"#{number} records added with #{number_of_syndicate_coordinators} syndicate coordinators, #{number_of_county_coordinators} county coordinators #{number_of_country_coordinators} country coordinators"
  end #end process
end
