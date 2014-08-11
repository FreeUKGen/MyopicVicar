class UseridDetail 
  include Mongoid::Document
include Mongoid::Timestamps::Created::Short
include Mongoid::Timestamps::Updated::Short
  
field :userid, type: String
field :userid_lower_case, type: String
field :syndicate, type: String
field :submitter_number, type: String
field :person_surname, type: String
field :person_forename, type: String
field :email_address, type: String
field :email_address_confirmation, type: String
field :address, type: String
field :telephone_number, type: String
field :skill_level, type: String, default: 'Unspecified'
field :fiche_reader, type: Boolean
field :password, type: String
field :password_confirmation, type: String
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
field :skill_notes, type: String 
index({ email_address: 1 })
index({ userid: 1, system_administrator: 1 })
index({ userid: 1, data_manager: 1 })
index({ userid: 1, syndicate_coordinator: 1 })
index({ userid: 1, county_coordinator: 1 })
index({ userid: 1, country_coordinator: 1 })
index({ userid: 1, syndicate: 1 })
index({ userid: 1, chapman_code: 1 })
index({ userid: 1, volunteer_coordinator: 1 })
scope :syndicate, ->(syndicate) { where(:syndicate => syndicate) }
attr_protected 
#attr_accessible :email_address, email_address_confirm, :userid,:syndicate,:person_surname,:person_forename,:address,:telephone_number,:skill_level, :person_role, :sig_up_date

validate :userid_and_email_address_does_not_exist, on: :create
validate :email_address_does_not_exist, on: :update

before_create :add_lower_case_userid

after_create :write_userid_file, :save_to_refinery, :send_invitation_to_create_password

before_update :save_to_attic
after_update  :write_userid_file
#validate :syndicate_is_valid, on: :create
before_destroy :delete_refinery_user_and_userid_folder



def write_userid_file
   user = self
   details_dir = File.join(Rails.application.config.datafiles,user.userid)
    Dir.mkdir(details_dir)  unless Dir.exists?(details_dir)
   details_dir = File.join(details_dir,".uDetails")
       if File.file?(details_dir)
        save_to_attic
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
    details.puts "SyndicateName:#{user.syndicate}" 
    details.puts "SignUpDate:#{user.sign_up_date}" 
    details.puts "Person:#{user.person_role}"
    unless user.active

      details.puts "DisabledDate:#{user.disabled_date}"
      details.puts "DisabledReason:#{user.disabled_reason}"
      details.puts "Active:0"
      details.puts "Disabled:1"
    else
      details.puts "Active:1"
       details.puts "Disabled:0"
    end
   details.close
end
def save_to_refinery
  
  #avoid looping on password changes
  
   u = Refinery::User.where(:username => self.userid).first
   if u.nil? 
   u = Refinery::User.new
    end
    
    u.username = self.userid
    u.email = self.email_address
    u.password = 'Password' # no-op
    u.password_confirmation = 'Password' # no-op
    u.encrypted_password = self.password # actual encrypted password
    u.reset_password_token= Refinery::User.reset_password_token 
    u.reset_password_sent_at = Time.now
    u.userid_detail_id = self.id.to_s
    u.add_role('Refinery')
    p 'checking'
    a = self.active && self.person_role == 'technical'
    p a
    u.add_role('Superuser') if (self.active && self.person_role == 'technical') 
    
    u.save! 
    
end    
def send_invitation_to_create_password
  type = self.person_role
  UserMailer.invitation_to_register_researcher(self).deliver if type == 'researcher'
  UserMailer.invitation_to_register_transcriber(self).deliver if type == 'transcriber'
  UserMailer.invitation_to_register_technical(self).deliver if type == 'technical'
end
def send_invitation_to_reset_password
  UserMailer.invitation_to_reset_password(self).deliver
  
end

def save_to_attic
  #to-do unix permissions
    user = self
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

def userid_and_email_address_does_not_exist
  errors.add(:userid, "Already exits") if UseridDetail.where(:userid => self[:userid]).exists?
   errors.add(:userid, "Already exits") if Refinery::User.where(:username => self[:userid]).exists?
   errors.add(:email_address, "Already exits") if UseridDetail.where(:email_address => self[:email_address]).exists?
   errors.add(:email_address, "Already exits") if Refinery::User.where(:email => self[:email_address]).exists?
end

def email_address_does_not_exist
  if self.changed.include?('email_address')
   errors.add(:email_address, "Already exits") if UseridDetail.where(:email_address => self[:email_address]).exists?
   errors.add(:email_address, "Already exits") if Refinery::User.where(:email => self[:email_address]).exists?
 end
end
 
def add_lower_case_userid
  self[:userid_lower_case] = self[:userid].downcase
end

def self.update_number_of_files(user)
#need to think about doing an update
   userid = UseridDetail.where(:userid => user).first
   files = Freereg1CsvFile.where(:userid => user ).all
    if files.nil?
     userid[:number_of_files] = 0
     userid[:number_of_records] = 0
     userid[:last_upload] = nil
    else
     number = 0
     records = 0
      files.each do |my_file|
      	number  = number  + 1
      	records = records + my_file.records.to_i
      	userid[:last_upload] = my_file.uploaded_date if number == 1
      	  unless my_file.uploaded_date.nil? || userid[:last_upload].nil?
      	   uderid[:last_upload] = my_file.uploaded_date if my_file.uploaded_date.strftime("%s").to_i > userid[:last_upload].strftime("%s").to_i
          end
       end
       userid[:number_of_files] = number
       userid[:number_of_records] = records
       userid.save!
    end
 end



def finish_creation_setup
  UserMailer.notification_of_transcriber_creation(self).deliver   
end

def finish_researcher_creation_setup
  UserMailer.notification_of_researcher_registration(self).deliver
end
def finish_transcriber_creation_setup
   UserMailer.notification_of_transcriber_registration(self).deliver
end
def finish_technical_creation_setup
  UserMailer.notification_of_technical_registration(self).deliver
end

def add_fields(type)
   self.sign_up_date =  DateTime.now 
   self.active = true
    case 
    when type == 'Register Researcher'
      self.person_role = 'researcher'
      self.syndicate = 'Researcher'
    when type == 'Register Transcriber'
       self.person_role = 'transcriber'
    when type == 'Technical Registration'
      self.active  = false
      self.person_role = 'technical'
      self.syndicate = 'Technical'
    end
    password = Devise::Encryptable::Encryptors::Freereg.digest('temppasshope',nil,nil,nil)
    self.password = password
    self.password_confirmation = password
    self.userid = self.userid.downcase
end
def self.get_userids_for_display(syndicate,page)
  users = UseridDetail.all.order_by(userid_lower_case: 1) if syndicate == 'all'
   users = UseridDetail.where(:syndicate => syndicate).all.order_by(userid_lower_case: 1) unless syndicate == 'all'
   @userids = Array.new
           users.each do |user|
              @userids << user
           end
   @userids = Kaminari.paginate_array(@userids).page(page) 
 end
 def delete_refinery_user_and_userid_folder
   refinery_user = Refinery::User.where(:username => self.userid).first
   refinery_user.destroy unless refinery_user.nil?
   details_dir = File.join(Rails.application.config.datafiles,self.userid)
   FileUtils.rmdir(details_dir) if File.file?(details_dir)
 end

 

end #end class
