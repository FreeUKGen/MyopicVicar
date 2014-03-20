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


validate :userid_does_not_exist, on: :create

before_save :add_lower_case_userid
before_create :save_to_attic
after_create :write_userid_file
#validate :syndicate_is_valid, on: :create
 before_update :save_to_attic
  after_update :write_userid_file

def self.update_files(freereg_file)
  user = freereg_file.userid
  files = Freereg1CsvFile.where(:userid => user).all
  userid = UseridDetail.where(:userid => user).first
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

def write_userid_file
   
   details_dir = File.join(Rails.application.config.datafiles,self.userid)
   details_dir = File.join(details_dir,".uDetails")
       if File.file?(details_dir)
         p "file should not be there"
       end
  
    details = File.new(details_dir, "w") 
    details.puts "Surname:#{self.person_surname}" 
    details.puts "UserID:#{self.userid}"
    details.puts "DisabledDate:#{self.disabled_date}"
    details.puts "EmailID:#{self.email_address}"
    details.puts "Active:1"
    details.puts "Disabled:0"
    details.puts "GivenName:#{self.person_forename}" 
    details.puts "Country:#{self.address}" 
    details.puts "SyndicateID:#{ChapmanCode.values_at(self.syndicate)}" 
    details.puts "SignUpDate:#{self.sign_up_date}"  
            
end
    


def save_to_attic
  #to-do unix permissions
  
    details_dir = File.join(Rails.application.config.datafiles,self.userid)
    details_file = File.join(details_dir,".uDetails")
    
      if File.file?(details_file)
        p "dealing with existing file"
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
 
 def add_lower_case_userid
 	self[:userid_lower_case] = self[:userid].downcase

    files = Freereg1CsvFile.where(:userid => self[:userid] ).all
    if files.nil?
     self[:number_of_files] = 0
     self[:number_of_records] = 0
     self[:last_upload] = nil
    else
     number = 0
     records = 0
      files.each do |my_file|
      	number  = number  + 1
      	records = records + my_file.records.to_i
      	self[:last_upload] = my_file.uploaded_date if number == 1
      	unless my_file.uploaded_date.nil? || self[:last_upload].nil?
      	self[:last_upload] = my_file.uploaded_date if my_file.uploaded_date.strftime("%s").to_i > self[:last_upload].strftime("%s").to_i
         end
       end
       self[:number_of_files] = number
        self[:number_of_records] = records
        
    end
 end
end #end class
