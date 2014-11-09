class ReviewUseridDocs
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
    file_for_warning_messages = "log/review_userid_detail_messages.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
  @@message_file = File.new(file_for_warning_messages, "w")
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    old_base_directory = "/raid-test/freereg/users"
    new_base_directory = "/raid-test/freereg2/users"
    old_filenames = Array.new
    old_files = Array.new
    old_userid = Hash.new
    new_userid = Hash.new
    userids = range.split("/")

    if userids.length == 2
      old_pattern = File.join(old_base_directory,userids[0])
      old_files = Dir.glob(old_pattern, File::FNM_CASEFOLD).sort 
      old_files.each do |filename|
        pattern = File.join(filename,userids[1])
        fil = Dir.glob(pattern, File::FNM_DOTMATCH) 
        old_filenames << fil[0] unless fil[0].nil?
      end
    else
     @@message_file.puts "unknown range style"
    end

    new_filenames = Array.new
    new_files = Array.new
    userids = range.split("/")
    if userids.length == 2
      new_pattern = File.join(new_base_directory,userids[0])

      new_files = Dir.glob(new_pattern, File::FNM_CASEFOLD).sort 

      new_files.each do |filename|
       pattern = File.join(filename,userids[1])
       fil = Dir.glob(pattern, File::FNM_DOTMATCH) 
       new_filenames << fil[0] unless fil[0].nil?
      end
    else
   @@message_file.puts "unknown range style"
    end

 @@message_file.puts "Comparison of numbers #{old_filenames.length} in old set and #{new_filenames.length } in the new"

  

 @@message_file.puts "Started a Userid Detail review with a base directory at #{old_base_directory} and a range #{range} that translates to #{old_filenames.length} userids"
  

  old_number = 0
  old_filenames.each do |filename|
   old_number = old_number + 1
   old_fields = Hash.new
   old_header = Hash.new
   old_records = Array.new
   old_record = File.open(filename).read
   old_records = old_record.split("\n")

   old_records.each do |r|
    rx = r.split(":")
    old_fields[rx[0]] = rx[1]
    end #end record split
    old_fields.each_key do |fn|
      recs = FIELD_NAMES.assoc(fn)
      unless recs.nil?
        x  = old_fields.assoc(fn)
        old_header[recs[1]] = x[1]
      end # end unless
    end #end field

    old_header[:person_role] = "transcriber" if old_header[:person_role].nil?
    old_header[:previous_syndicate] = old_header[:syndicate]
    old_header[:syndicate] = SyndicateTranslation.values_at(old_header[:syndicate]) if old_header[:syndicate_name].nil?
   #files written in F2 may have a non county syndicate name
   old_header[:syndicate] = old_header[:syndicate_name] unless old_header[:syndicate_name].nil?
   old_header[:digest] = Digest::MD5.file(filename).hexdigest 

   old_header[:sign_up_date] = DateTime.strptime(old_header[:sign_up_date],'%s') unless old_header[:sign_up_date].nil?
   old_header[:disabled_date] = DateTime.strptime(old_header[:disabled_date],'%s') unless old_header[:disabled_date].nil?
   old_header[:fiche_reader] = old_header[:fiche_reader].to_i
   old_header[:fiche_reader] = false
   old_header[:active] = old_header[:active].to_i
   old_header[:disabled] = old_header[:disabled].to_i
   if old_header[:active] == 0  || old_header[:disabled] == 1 || !old_header[:disabled_date].nil? || !old_header[:disabled_reason].nil? 
     old_header[:active] = false     
   end
   old_header[:userid_lower_case] =  old_header[:userid].downcase
   old_userid[old_header[:userid]] = old_header
 end # end filename old

new_number = 0
new_filenames.each do |filename|
   new_number = new_number + 1
   new_fields = Hash.new
   new_header = Hash.new
   new_records = Array.new
   new_record = File.open(filename).read
   new_records = new_record.split("\n")

   new_records.each do |r|
    rx = r.split(":")
    new_fields[rx[0]] = rx[1]
    end #end record split

   new_fields.each_key do |fn|
      recs = FIELD_NAMES.assoc(fn)
      unless recs.nil?
        x  = new_fields.assoc(fn)
        new_header[recs[1]] = x[1]
      end # end unless
    end #end field

    new_header[:person_role] = "transcriber" if new_header[:person_role].nil?
    new_header[:previous_syndicate] = new_header[:syndicate]
    new_header[:syndicate] = SyndicateTranslation.values_at(new_header[:syndicate]) if new_header[:syndicate_name].nil?
   #files written in F2 may have a non county syndicate name
   new_header[:syndicate] = new_header[:syndicate_name] unless new_header[:syndicate_name].nil?
   new_header[:digest] = Digest::MD5.file(filename).hexdigest 

   new_header[:sign_up_date] = DateTime.strptime(new_header[:sign_up_date],'%s') unless new_header[:sign_up_date].nil?
   new_header[:disabled_date] = DateTime.strptime(new_header[:disabled_date],'%s') unless new_header[:disabled_date].nil?
   new_header[:fiche_reader] = new_header[:fiche_reader].to_i
   new_header[:fiche_reader] = false
   new_header[:active] = new_header[:active].to_i
   new_header[:disabled] = new_header[:disabled].to_i

   if new_header[:active] == 0  || new_header[:disabled] == 1 || !new_header[:disabled_date].nil? || !new_header[:disabled_reason].nil? 
     new_header[:active] = false     
    end

   new_header[:userid_lower_case] =  new_header[:userid].downcase
   new_userid[new_header[:userid]] = new_header
 end # end filename new

old_number = 0
 old_userid.each_key do |userid|
  if new_userid.assoc(userid).nil?
   old_number = old_number + 1
   missing_userid = userid
   missing_detail = old_userid[userid]
  @@message_file.puts "Dropped #{missing_userid} missing in the new file set with details #{missing_detail}"
 end 
end

new_number = 0
new_userid.each_key do |userid|
  if new_userid.assoc(userid).nil?
   new_number = new_number + 1
   missing_userid = userid
   missing_detail = new_userid[userid]
  @@message_file.puts "Added #{missing_userid} missing in the old file set with details #{missing_detail}"
 end 
end


@@message_file.puts "#{old_number} missing in new and #{new_number} missing in old"

old_number = 0
old_userid.each_key do |userid|
  down_userid = userid.downcase
  if !old_userid.assoc(down_userid).nil? && userid != down_userid
   old_number = old_number + 1
   duplicated_userid = userid
   duplicated_detail = old_userid[userid]
  @@message_file.puts duplicated_userid
  @@message_file.puts duplicated_detail
 end 
end 

new_number = 0
new_userid.each_key do |userid|
  down_userid = userid.downcase
  if !new_userid.assoc(down_userid).nil? && userid != down_userid
   new_number = new_number + 1
   duplicated_userid = userid
   duplicated_detail = new_userid[userid]
  @@message_file.puts duplicated_userid
  @@message_file.puts duplicated_detail
 end 
end 

@@message_file.puts "#{old_number} case sensitive duplicates in old and #{new_number} case sensitive duplicates in new "

old_number = 0
old_hash_email_addresses = Hash.new
email_addresses = Array.new
duplicated_email_addresses = Array.new
unique_email_addresses = Array.new
duplicated_email = Hash.new
old_userid.each_pair do |user,userid|
  email_addresses << userid[:email_address]
  old_hash_email_addresses[user] = userid[:email_address]
 end

duplicated_email_addresses = email_addresses.select{|item| email_addresses.count(item) > 1}.uniq

unique_email_addresses = email_addresses.uniq
old_duplicated_email_addresses = duplicated_email_addresses.length

duplicated_email_addresses.each do |dupemail|
  duplicated_userid = Array.new
  old_hash_email_addresses.each_pair do |user,email|
   duplicated_userid  << user if dupemail == email
  end
  duplicated_email[dupemail] =  duplicated_userid
end



@@message_file.puts "Duplicated email #{duplicated_email} in old data set"
new_number = 0
new_hash_email_addresses = Hash.new
email_addresses = Array.new
duplicated_email_addresses = Array.new
unique_email_addresses = Array.new
duplicated_email = Hash.new
new_userid.each_pair do |user,userid|
  email_addresses << userid[:email_address]
  new_hash_email_addresses[user] = userid[:email_address]
end

duplicated_email_addresses = email_addresses.select{|item| email_addresses.count(item) > 1}.uniq

unique_email_addresses = email_addresses.uniq
new_duplicated_email_addresses = duplicated_email_addresses.length

duplicated_email_addresses.each do |dupemail|
  duplicated_userid = Array.new
  new_hash_email_addresses.each_pair do |user,email|
   duplicated_userid  << user if dupemail == email
  end
  duplicated_email[dupemail] =  duplicated_userid
end
@@message_file.puts "Duplicated email #{duplicated_email} in new data set"
@@message_file.puts "#{ old_duplicated_email_addresses} duplicated email addresses in old and #{new_duplicated_email_addresses} duplicated email addresses in new "


 
 end #end process
end