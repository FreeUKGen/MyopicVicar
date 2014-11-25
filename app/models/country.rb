class Country
 include Mongoid::Document
 include Mongoid::Timestamps::Created::Short
 include Mongoid::Timestamps::Updated::Short

 field :country_code, type: String
 field :country_coordinator, type: String
 field :country_coordinator_lower_case, type: String
 field :previous_country_coordinator, type: String
 field :country_description, type: String
 field :country_notes, type: String
 field :counties_included, type: Array
 before_save :add_lower_case_and_change_userid_fields

 index ({ country_code: 1, country_coordinator: 1 })
 index ({ country_coordinator: 1 })
 index ({ previous_country_coordinator: 1 })
 index ({ country_coordinator_lower_case: 1})
 index ({ country_code: 1, country_coordinator_lower_case: 1 })
 index ({ country_code: 1, previous_country_coordinator: 1 })

 def  add_lower_case_and_change_userid_fields
  self.country_coordinator_lower_case = self.country_coordinator.downcase
  
end
def update_fields_before_applying(parameters)
 previous_country_coordinator = self.country_coordinator
 parameters[:previous_country_coordinator] = previous_country_coordinator  unless self.country_coordinator == parameters[:country_coordinator]
  unless self.country_coordinator == parameters[:country_coordinator] #no change in coordinator
    if UseridDetail.where(:userid => previous_country_coordinator).exists? then #make sure that 
     @old_userid = UseridDetail.where(:userid => previous_country_coordinator).first 
     if @old_userid.country_groups.length == 1
      unless  @old_userid.person_role.nil?
        @old_userid.person_role = 'transcriber'  unless (@old_userid.person_role == 'syndicate_coordinator' || @old_userid.person_role == 'country_coordinator' || @old_userid.person_role == 'system_adminstrator' || @old_userid.person_role == 'volunteer_coordinator')
      end 
    end
    @old_userid.country_groups.delete_if {|code| code == self.country_code}
    @old_userid.save(:validate => false)  unless @old_userid.nil?
    end
    if UseridDetail.where(:userid => parameters[:country_coordinator]).exists? then # make sure there is a new coordinator to upgrade
     @new_userid = UseridDetail.where(:userid => parameters[:country_coordinator]).first
     if @new_userid.country_groups.empty? || @new_userid.country_groups.length == 0 then
       @new_userid.person_role = 'country_coordinator' if (@new_userid.person_role == 'transcriber' || @new_userid.person_role == 'syndicate_coordinator' || @new_userid.person_role == 'researcher' || @new_userid.person_role == 'county_coordinator' )
     end 
     @new_userid.country_groups = self.counties_included
     @new_userid.country_groups = @new_userid.country_groups.compact
     @new_userid.save(:validate => false)  unless @new_userid.nil?
    end
  end   
 parameters
end
end
