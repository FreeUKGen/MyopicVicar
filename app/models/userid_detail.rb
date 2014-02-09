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
field :skill_level, type: String
field :fiche_reader, type: Boolean
field :password, type: String
field :chapman_code, type: String 
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

validate :person_role_is_valid, on: :create

before_save :add_lower_case_userid
#validate :syndicate_is_valid, on: :create


 def person_role_is_valid
   
	errors.add(:person_code, "The person role is invalid") unless UseridRole.has_key?(self[:person_role])
    
 end #end def

 def syndicate_is_valid
 	  errors.add(:chapman_code, "The syndicate code is incorrect") unless ChapmanCode.value?(self[:chapman_code])
 end #end def
 
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
