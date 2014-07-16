class UseridDetail
  include Mongoid::Document
include Mongoid::Timestamps::Created::Short
include Mongoid::Timestamps::Updated::Short
  require 'chapman_code'
  require 'userid_role'
field :userid, type: String
field :userid_lower_case, type: String
field :syndicate, type: String
field :submitter_number, type: String
field :person_surname, type: String
field :person_forename, type: String
field :email_address, type: String
field :address, type: String
field :telephone_number, type: String
field :skill_level, type: String, default: 'Unspecified'
field :fiche_reader, type: Boolean
field :password, type: String
field :previous_syndicate, type: String 
field :active, type: Boolean
field :last_upload, type: DateTime
field :number_of_files, type: Integer, default: 0
field :number_of_records, type: Integer, default: 0 
field :sign_up_date, type: DateTime
field :disabled_date, type: DateTime
field :disabled_reason, type: String
field :person_role, type: String, default: 'researcher'
field :syndicate_groups, type: Array
field :county_groups, type: Array
field :country_groups, type: Array
field :digest, type: String, default: nil
index({ userid: 1, system_administrator: 1 })
index({ userid: 1, data_manager: 1 })
index({ userid: 1, syndicate_coordinator: 1 })
index({ userid: 1, county_coordinator: 1 })
index({ userid: 1, country_coordinator: 1 })
index({ userid: 1, syndicate: 1 })
index({ userid: 1, chapman_code: 1 })
index({ userid: 1, volunteer_coordinator: 1 })
scope :syndicate, ->(syndicate) { where(:syndicate => syndicate) }


validate :userid_does_not_exist, on: :create

before_save :add_lower_case_userid
#before_update :save_to_attic
#after_update :write_userid_file
#validate :syndicate_is_valid, on: :create
 

def self.update_files(freereg_file)
  user = freereg_file.userid
  files = Freereg1CsvFile.where(:userid => user).all
  userid = UseridDetail.where(:userid => user).first
  p user if  userid.nil?
  unless  userid.nil?
    if files.nil?
    userid.number_of_files = 0
    userid.number_of_records = 0
    userid.last_upload = nil
    else
     number = 0
     records = 0
      files.each do |my_file|
        number  = number  + 1
        records = records + my_file.records.to_i
        userid.last_upload = my_file.uploaded_date if number == 1
        unless my_file.uploaded_date.nil? || userid.last_upload.nil?
        userid.last_upload = my_file.uploaded_date if my_file.uploaded_date.strftime("%s").to_i > userid.last_upload.strftime("%s").to_i
         end
       end
       userid.number_of_files = number
       userid.number_of_records = records
       userid.save 
    end
  end
end

def write_userid_file(user)
   
   details_dir = File.join(Rails.application.config.datafiles,user.userid)
   details_dir = File.join(details_dir,".uDetails")
       if File.file?(details_dir)
         p "file should not be there"
       end
  
    details = File.new(details_dir, "w") 
    details.puts "Surname:#{user.person_surname}" 
    details.puts "UserID:#{user.userid}"
    details.puts "EmailID:#{user.email_address}"
    details.puts "Password:#{user.password}"
    details.puts "GivenName:#{user.person_forename}" 
    details.puts "Country:#{user.address}" 
    details.puts "SyndicateID:#{ChapmanCode.values_at(user.syndicate)}" 
    details.puts "SignUpDate:#{user.sign_up_date}" 
    details.puts "Person:#{user.person_role}"
    unless active

    details.puts "DisabledDate:#{user.disabled_date}"
    details.puts "DisabledReason:#{user.disabled_reason}"
    details.puts "Active:0"
    details.puts "Disabled:1"
  else
    details.puts "Active:1"
    details.puts "Disabled:0"
  end
   details.close
   user.save_to_refinery
            
end
def save_to_refinery

   u = Refinery::User.where(:username => self.userid).first
    if u.nil? 
     u = Refinery::User.new
    end
    u.username = self.userid
    u.email = self.email_address
    u.password = 'Password' # no-op
    u.password_confirmation = 'Password' # no-op

    u.encrypted_password = self.password # actual encrypted password
    u.userid_detail_id = self.id.to_s
    u.add_role("Refinery")
    u.save      
end    


def save_to_attic(user)
  #to-do unix permissions
  
    details_dir = File.join(Rails.application.config.datafiles,user.userid)
    details_file = File.join(details_dir,".uDetails")
    
      if File.file?(details_file)
        newdir = File.join(details_dir,'.attic')
        Dir.mkdir(newdir) unless Dir.exists?(newdir)
        renamed_file = (details_file + "." + (Time.now.to_i).to_s).to_s
        File.rename(details_file,renamed_file)
        FileUtils.mv(renamed_file,newdir)

       else 
        Dir.mkdir(details_dir)  unless Dir.exists?(details_dir)
        end
 end

 def userid_does_not_exist
  errors.add(:userid, "Already exits") if UseridDetail.where(:userid => self[:userid]).first
 end
 
 def add_lower_case_userid(user)
 	user[:userid_lower_case] = user[:userid].downcase

    files = Freereg1CsvFile.where(:userid => user[:userid] ).all
    if files.nil?
     user[:number_of_files] = 0
     user[:number_of_records] = 0
     user[:last_upload] = nil
    else
     number = 0
     records = 0
      files.each do |my_file|
      	number  = number  + 1
      	records = records + my_file.records.to_i
      	user[:last_upload] = my_file.uploaded_date if number == 1
      	unless my_file.uploaded_date.nil? || user[:last_upload].nil?
      	user[:last_upload] = my_file.uploaded_date if my_file.uploaded_date.strftime("%s").to_i > user[:last_upload].strftime("%s").to_i
         end
       end
       user[:number_of_files] = number
        user[:number_of_records] = records
        
    end
 end
end #end class
