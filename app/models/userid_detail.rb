class UseridDetail
  include Mongoid::Document

  require 'chapman_code'
  require 'userid_role'
field :userid, type: String
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
field :sign_up_date, type: DateTime
field :disabled_date, type: DateTime
field :disabled_reason, type: String
field :person_role, type: String, default: 'researcher'

index({ userid: 1, syndicate: 1 })
index({ userid: 1, chapman_code: 1 })

validate :person_role_is_valid, on: :create
#validate :syndicate_is_valid, on: :create


 def person_role_is_valid
   
	errors.add(:person_code, "The person role is invalid") unless UseridRole.has_key?(self[:person_role])
    
 end #end def

 def syndicate_is_valid
 	  errors.add(:chapman_code, "The syndicate code is incorrect") unless ChapmanCode.value?(self[:chapman_code])
 end #end def
 
end #end class
